# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2018, by Janko Marohnić.
# Copyright, 2021, by Aurora Nockert.
# Copyright, 2023, by Maruth Goyal.

require_relative 'buffer'
require_relative 'generic'

require 'async/semaphore'

module Async
	module IO
		class Stream
			BLOCK_SIZE = IO::BLOCK_SIZE
			
			def self.open(path, mode = "r+", **options)
				stream = self.new(File.open(path, mode), **options)
				
				return stream unless block_given?
				
				begin
					yield stream
				ensure
					stream.close
				end
			end
			
			def initialize(io, block_size: BLOCK_SIZE, maximum_read_size: MAXIMUM_READ_SIZE, sync: true, deferred: false)
				@io = io
				@eof = false
				
				@pending = 0
				# This field is ignored, but used to mean, try to buffer packets in a single iteration of the reactor.
				# @deferred = deferred
				
				@writing = Async::Semaphore.new(1)
				
				# We don't want Ruby to do any IO buffering.
				@io.sync = sync
				
				@block_size = block_size
				@maximum_read_size = maximum_read_size
				
				@read_buffer = Buffer.new
				@write_buffer = Buffer.new
				@drain_buffer = Buffer.new
				
				# Used as destination buffer for underlying reads.
				@input_buffer = Buffer.new
			end
			
			attr :io
			
			attr :block_size
			
			# Reads `size` bytes from the stream. If size is not specified, read until end of file.
			def read(size = nil)
				return String.new(encoding: Encoding::BINARY) if size == 0
				
				if size
					until @eof or @read_buffer.bytesize >= size
						# Compute the amount of data we need to read from the underlying stream:
						read_size = size - @read_buffer.bytesize
						
						# Don't read less than @block_size to avoid lots of small reads:
						fill_read_buffer(read_size > @block_size ? read_size : @block_size)
					end
				else
					until @eof
						fill_read_buffer
					end
				end
				
				return consume_read_buffer(size)
			end
			
			# Read at most `size` bytes from the stream. Will avoid reading from the underlying stream if possible.
			def read_partial(size = nil)
				return String.new(encoding: Encoding::BINARY) if size == 0
			
				if !@eof and @read_buffer.empty?
					fill_read_buffer
				end
				
				return consume_read_buffer(size)
			end
			
			def read_exactly(size, exception: EOFError)
				if buffer = read(size)
					if buffer.bytesize != size
						raise exception, "could not read enough data"
					end
					
					return buffer
				end
				
				raise exception, "encountered eof while reading data"
			end
			
			def readpartial(size = nil)
				read_partial(size) or raise EOFError, "Encountered eof while reading data!"
			end
			
			# Efficiently read data from the stream until encountering pattern.
			# @param pattern [String] The pattern to match.
			# @return [String] The contents of the stream up until the pattern, which is consumed but not returned.
			def read_until(pattern, offset = 0, chomp: true)
				# We don't want to split on the pattern, so we subtract the size of the pattern.
				split_offset = pattern.bytesize - 1
				
				until index = @read_buffer.index(pattern, offset)
					offset = @read_buffer.bytesize - split_offset
					
					offset = 0 if offset < 0
					
					return unless fill_read_buffer
				end
				
				@read_buffer.freeze
				matched = @read_buffer.byteslice(0, index+(chomp ? 0 : pattern.bytesize))
				@read_buffer = @read_buffer.byteslice(index+pattern.bytesize, @read_buffer.bytesize)
				
				return matched
			end
			
			def peek(size = nil)
				if size
					until @eof or @read_buffer.bytesize >= size
						# Compute the amount of data we need to read from the underlying stream:
						read_size = size - @read_buffer.bytesize
						
						# Don't read less than @block_size to avoid lots of small reads:
						fill_read_buffer(read_size > @block_size ? read_size : @block_size)
					end
					return @read_buffer.slice(0, [size, @read_buffer.size].min)
				end
				until (block_given? && yield(@read_buffer)) or @eof
					fill_read_buffer
				end
				return @read_buffer
			end
			
			def gets(separator = $/, **options)
				read_until(separator, **options)
			end
			
			# Flushes buffered data to the stream.
			def flush
				return if @write_buffer.empty?
				
				@writing.acquire do
					# Flip the write buffer and drain buffer:
					@write_buffer, @drain_buffer = @drain_buffer, @write_buffer
					
					begin
						@io.write(@drain_buffer)
					ensure
						# If the write operation fails, we still need to clear this buffer, and the data is essentially lost.
						@drain_buffer.clear
					end
				end
			end
			
			# Writes `string` to the buffer. When the buffer is full or #sync is true the
			# buffer is flushed to the underlying `io`.
			# @param string the string to write to the buffer.
			# @return the number of bytes appended to the buffer.
			def write(string)
				@write_buffer << string
				
				if @write_buffer.bytesize >= @block_size
					flush
				end
				
				return string.bytesize
			end
			
			# Writes `string` to the stream and returns self.
			def <<(string)
				write(string)
				
				return self
			end
			
			def puts(*arguments, separator: $/)
				arguments.each do |argument|
					@write_buffer << argument << separator
				end
				
				flush
			end
			
			def connected?
				@io.connected?
			end
			
			def readable?
				@io.readable?
			end
			
			def closed?
				@io.closed?
			end
			
			def close_read
				@io.close_read
			end
			
			def close_write
				flush
			ensure
				@io.close_write
			end
			
			# Best effort to flush any unwritten data, and then close the underling IO.
			def close
				return if @io.closed?
				
				begin
					flush
				rescue
					# We really can't do anything here unless we want #close to raise exceptions.
				ensure
					@io.close
				end
			end
			
			# Returns true if the stream is at file which means there is no more data to be read.
			def eof?
				if !@read_buffer.empty?
					return false
				elsif @eof
					return true
				else
					return @io.eof?
				end
			end
			
			alias eof eof?
			
			def eof!
				@read_buffer.clear
				@eof = true
				
				raise EOFError
			end
			
			private
			
			def sysread(size, buffer)
				while true
					result = @io.read_nonblock(size, buffer, exception: false)
					
					case result
					when :wait_readable
						@io.wait_readable
					when :wait_writable
						@io.wait_writable
					else
						return result
					end
				end
			end
			
			# Fills the buffer from the underlying stream.
			def fill_read_buffer(size = @block_size)
				# We impose a limit because the underlying `read` system call can fail if we request too much data in one go.
				if size > @maximum_read_size
					size = @maximum_read_size
				end
				
				# This effectively ties the input and output stream together.
				flush
				
				if @read_buffer.empty?
					if sysread(size, @read_buffer)
						# Console.logger.debug(self, name: "read") {@read_buffer.inspect}
						return true
					end
				else
					if chunk = sysread(size, @input_buffer)
						@read_buffer << chunk
						# Console.logger.debug(self, name: "read") {@read_buffer.inspect}
						
						return true
					end
				end
				
				# else for both cases above:
				@eof = true
				return false
			end
			
			# Consumes at most `size` bytes from the buffer.
			# @param size [Integer|nil] The amount of data to consume. If nil, consume entire buffer.
			def consume_read_buffer(size = nil)
				# If we are at eof, and the read buffer is empty, we can't consume anything.
				return nil if @eof && @read_buffer.empty?
				
				result = nil
				
				if size.nil? or size >= @read_buffer.bytesize
					# Consume the entire read buffer:
					result = @read_buffer
					@read_buffer = Buffer.new
				else
					# This approach uses more memory.
					# result = @read_buffer.slice!(0, size)
					
					# We know that we are not going to reuse the original buffer.
					# But byteslice will generate a hidden copy. So let's freeze it first:
					@read_buffer.freeze
					
					result = @read_buffer.byteslice(0, size)
					@read_buffer = @read_buffer.byteslice(size, @read_buffer.bytesize)
				end
				
				return result
			end
		end
	end
end
