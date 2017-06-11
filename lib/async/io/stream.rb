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
			def initialize(io, block_size: 1024*4, sync: false)
				@io = io
				@eof = false
				
				@block_size = block_size
				@sync = sync
				
				@read_buffer = BinaryString.new
				@write_buffer = BinaryString.new
			end
			
			attr :io
			
			# The "sync mode" of the stream. See IO#sync for full details.
			attr_accessor :sync
			
			# Reads `size` bytes from the stream. If size is not specified, read until end of file.
			def read(size = nil)
				return "" if size == 0
				
				until @eof || (size && size <= @read_buffer.size)
					fill_read_buffer
				end

				return consume_read_buffer(size)
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

			# Writes `string` to the stream and returns self.
			def <<(string)
				write(string)
				
				return self
			end

			# Flushes buffered data to the stream.
			def flush
				syswrite(@write_buffer)
				@write_buffer.clear
			end

			# Closes the stream and flushes any unwritten data.
			def close
				flush rescue nil
				
				@io.close
			end

			# Returns true if the stream is at file which means there is no more data to be read.
			def eof?
				fill_read_buffer if !@eof && @read_buffer.empty?
				
				return @eof && @read_buffer.empty?
			end
			
			alias eof eof?
			
			# Efficiently read data from the stream until encountering pattern.
			# @param pattern [String] The pattern to match.
			# @return [String] The contents of the stream up until the pattern, which is consumed but not returned.
			def read_until(pattern)
				index = @read_buffer.index(pattern)
				
				until index || @eof
					fill_read_buffer
					
					index = @read_buffer.index(pattern)
				end
				
				if line = consume_read_buffer(index)
					consume_read_buffer(pattern.bytesize)
					
					return line
				end
			end
			
			def peek
				until yield(@read_buffer) || @eof
					fill_read_buffer
				end
			end
			
			private
			
			# Fills the buffer from the underlying stream.
			def fill_read_buffer
				if @read_buffer.empty?
					unless @io.read(@block_size, @read_buffer)
						@eof = true
					end
				elsif buffer = @io.read(@block_size)
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
