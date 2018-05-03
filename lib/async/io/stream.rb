# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'binary_string'
require_relative 'generic'

module Async
	module IO
		class Stream
			# The default block size for IO buffers.
			# BLOCK_SIZE = ENV.fetch('BLOCK_SIZE', 1024*16).to_i
			BLOCK_SIZE = 1024*8
			
			def initialize(io, block_size: BLOCK_SIZE, sync: true)
				@io = io
				@eof = false
				
				# We don't want Ruby to do any IO buffering.
				@io.sync = sync
				
				@block_size = block_size
				
				@read_buffer = BinaryString.new
				@write_buffer = BinaryString.new
			end
			
			attr :io
			attr :block_size
			
			# Reads `size` bytes from the stream. If size is not specified, read until end of file.
			def read(size = nil)
				return '' if size == 0
				
				if size
					fill_read_buffer until @eof or @read_buffer.size >= size
				else
					fill_read_buffer until @eof
				end
				
				return consume_read_buffer(size)
			end
			
			# Read at most `size` bytes from the stream. Will avoid reading from the underlying stream if possible.
			def read_partial(size = nil)
				return '' if size == 0
				
				if @read_buffer.empty? and !@eof
					fill_read_buffer
				end
				
				return consume_read_buffer(size)
			end
			
			# Efficiently read data from the stream until encountering pattern.
			# @param pattern [String] The pattern to match.
			# @return [String] The contents of the stream up until the pattern, which is consumed but not returned.
			def read_until(pattern, offset = 0)
				until index = @read_buffer.index(pattern, offset)
					offset = @read_buffer.size
					
					return unless fill_read_buffer
				end
				
				matched = @read_buffer.slice!(0, index)
				@read_buffer.slice!(0, pattern.bytesize)
				
				return matched
			end
			
			def peek
				until yield(@read_buffer) || @eof
					fill_read_buffer
				end
			end
			
			# Writes `string` to the buffer. When the buffer is full or #sync is true the
			# buffer is flushed to the underlying `io`.
			# @param string the string to write to the buffer.
			# @return the number of bytes appended to the buffer.
			def write(string)
				if @write_buffer.empty? and string.bytesize >= @block_size
					syswrite(string)
				else
					@write_buffer << string
					
					if @write_buffer.size >= @block_size
						syswrite(@write_buffer)
						@write_buffer.clear
					end
				end
				
				return string.bytesize
			end

			# Writes `string` to the stream and returns self.
			def <<(string)
				write(string)
				
				return self
			end

			# Flushes buffered data to the stream.
			def flush
				unless @write_buffer.empty?
					syswrite(@write_buffer)
					@write_buffer.clear
				end
			end

			def gets(separator = $/)
				flush
				
				read_until(separator)
			end

			def puts(*args, separator: $/)
				args.each do |arg|
					@write_buffer << arg << separator
				end
				
				flush
			end
			
			def connected?
				@io.connected?
			end
			
			def closed?
				@io.closed?
			end
			
			# Closes the stream and flushes any unwritten data.
			def close
				return if @io.closed?
				
				begin
					flush
				rescue
					# We really can't do anything here unless we want #close to raise exceptions.
					Async.logger.error(self) {$!}
				ensure
					@io.close
				end
			end

			# Returns true if the stream is at file which means there is no more data to be read.
			def eof?
				fill_read_buffer if !@eof && @read_buffer.empty?
				
				return @eof && @read_buffer.empty?
			end
			
			alias eof eof?
			
			def eof!
				@read_buffer.clear
				@eof = true
				
				raise EOFError
			end
			
			private
			
			# Fills the buffer from the underlying stream.
			def fill_read_buffer
				# Can we read directly into the buffer? (Ruby doesn't support append, only replace):
				if @read_buffer.empty?
					if @io.read(@block_size, @read_buffer)
						return true
					end
				elsif chunk = @io.read(@block_size)
					@read_buffer << chunk
					return true
				end
				
				# We didn't read anything, so we must be at eof:
				@eof = true
				return false
			end

			# Consumes at most `size` bytes from the buffer.
			# @param size [Integer|nil] The amount of data to consume. If nil, consume entire buffer.
			def consume_read_buffer(size = nil)
				# If we are at eof, and the read buffer is empty, we can't consume anything.
				return nil if @eof && @read_buffer.empty?
				
				result = nil
				
				if size == nil || size >= @read_buffer.size
					# Consume the entire read buffer:
					result = @read_buffer.dup
					@read_buffer.clear
				else
					# Consume only part of the read buffer:
					result = @read_buffer.slice!(0, size)
				end
				
				return result
			end
			
			# Write a buffer to the underlying stream.
			# @param buffer [String] The string to write, any encoding is okay.
			def syswrite(buffer)
				remaining = buffer.bytesize
				
				# Fast path:
				written = @io.write(buffer)
				return if written == remaining
				
				# Slow path:
				remaining -= written
				
				while remaining > 0
					wrote = @io.write(buffer.byteslice(written, remaining))
					
					remaining -= wrote
					written += wrote
				end
				
				return written
			end
		end
	end
end
