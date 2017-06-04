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

require 'socket'
require_relative 'generic'

module Async
	module IO
		class BinaryString < String
			def initialize(*args)
				super
				
				force_encoding(Encoding::BINARY)
			end
			
			def << string
				super
				
				force_encoding(Encoding::BINARY)
			end
			
			alias concat <<
		end
		
		class Stream
			include Enumerable
			
			def initialize(io, block_size: 1024, eol: $/)
				@io = io
				@eof = false
				@sync = false
				
				@block_size = block_size
				@eol = eol
				
				@read_buffer = BinaryString.new
				@write_buffer = BinaryString.new
			end
			
			attr :io
			
			# The "sync mode" of the stream. See IO#sync for full details.
			attr_accessor :sync
			
			# Reads `size` bytes from the stream.  If `buffer` is provided it must
			# reference a string which will receive the data.
			#
			# See IO#read for full details.
			def read(size = nil, output_buffer = nil)
				if size == 0
					if output_buffer
						output_buffer.clear
						return output_buffer
					else
						return ""
					end
				end

				until @eof
					break if size && size <= @read_buffer.size
					fill_read_buffer
					break unless size
				end

				buffer = consume_read_buffer(size)

				if buffer && output_buffer
					output_buffer.replace(buffer)
					buffer = output_buffer
				end

				if size
					return buffer
				else
					return buffer || ""
				end
			end

			# Writes `string` to the buffer. When the buffer is full or #sync is true the
			# buffer is flushed to the underlying `io`.
			# @param string the string to write to the buffer.
			# @return the number of bytes appended to the buffer.
			def write(string)
				@write_buffer << string
				
				if @sync || @write_buffer.size > @block_size
					flush
				end
				
				return string.bytesize
			end

			# Flushes buffered data to the stream.
			def flush
				syswrite(@write_buffer)
			end

			# Closes the stream and flushes any unwritten data.
			def close
				flush rescue nil
				
				@io.close
			end

			# Reads the next line from the stream. Lines are separated by +eol+. If
			# +limit+ is provided the result will not be longer than the given number of
			# bytes.
			#
			# +eol+ may be a String or Regexp.
			#
			# Unlike IO#gets the line read will not be assigned to +$_+.
			#
			# Unlike IO#gets the separator must be provided if a limit is provided.
			def gets(eol = @eol, limit = nil)
				index = @read_buffer.index(eol)
				
				until index || @eof
					fill_read_buffer
					index = @read_buffer.index(eol)
				end

				if eol.is_a?(Regexp)
					size = index ? index+$&.bytesize : nil
				else
					size = index ? index+eol.bytesize : nil
				end

				if limit && limit >= 0
					size = [size, limit].min
				end

				consume_read_buffer(size)
			end

			# Executes the block for every line in the stream where lines are separated
			# by +eol+.
			#
			# See also #gets
			def each(eol = @eol)
				while line = self.gets(eol)
					yield line
				end
			end
			alias each_line each

			# Reads lines from the stream which are separated by +eol+.
			#
			# See also #gets
			def readlines(eol = @eol)
				lines = []

				while line = self.gets(eol)
					lines << line
				end

				lines
			end

			# Reads a line from the stream which is separated by +eol+.
			#
			# Raises EOFError if at end of file.
			def readline(eol=@eol)
				gets(eol) or raise EOFError
			end

			# Reads one character from the stream.  Returns nil if called at end of
			# file.
			def getc
				read(1)
			end

			# Calls the given block once for each byte in the stream.
			def each_byte # :yields: byte
				while c = getc
					yield(c.ord)
				end
			end

			# Reads a one-character string from the stream.  Raises an EOFError at end
			# of file.
			def readchar
				getc or raise EOFError
			end

			# Returns true if the stream is at file which means there is no more data to be read.
			def eof?
				fill_read_buffer if !@eof && @read_buffer.empty?
				
				@eof && @read_buffer.empty?
			end
			alias eof eof?

			# Writes `string` to the stream.
			def <<(string)
				write(string)
				
				return self
			end

			# Writes `args` to the stream along with a record separator. See `IO#puts` for full details.
			def puts(*args, eol: @eol)
				if args.empty?
					write(eol)
				else
					args.each do |arg|
						string = arg.to_s
						if string.end_with? eol
							write(string)
						else
							write(string)
							write(eol)
						end
					end
				end
				
				return nil
			end

			# Writes `args` to the stream. See `IO#print` for full details.
			def print(*args)
				args.each do |arg|
					write(arg.to_s)
				end
				
				return nil
			end

			# Formats and writes to the stream converting parameters under control of the format string. See `Kernel#sprintf` for format string details.
			def printf(s, *args)
				write(s % args)
				
				return nil
			end

			private
			
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

			# Fills the buffer from the underlying stream.
			def fill_read_buffer
				if buffer = @io.read(@block_size)
					# We guarantee that the read_buffer remains ASCII-8BIT because read should always return ASCII-8BIT 
					@read_buffer << buffer
				else
					@eof = true
				end
			end

			# Consumes `size` bytes from the buffer.
			# @param size [Integer|nil] The amount of data to consume. If nil, consume entire buffer.
			def consume_read_buffer(size = nil)
				# If we are at eof, and the read buffer is empty, we can't consume anything.
				return nil if @eof && @read_buffer.empty?
				
				result = nil
				
				if size == nil || size == @read_buffer.size
					# Consume the entire read buffer:
					result = @read_buffer.dup
					@read_buffer.clear
				else
					# Consume only part of the read buffer:
					result = @read_buffer.slice!(0, size)
				end
				
				return result
			end
		end
	end
end
