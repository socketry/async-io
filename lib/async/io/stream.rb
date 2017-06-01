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
		class Stream
			include Enumerable
			
			def initialize(io, block_size: 1024, eol: $/)
				@io = io
				@eof = false
				@sync = false
				
				@block_size = block_size
				@eol = eol
				
				@read_buffer = String.new
				@write_buffer = String.new
				
				if encoding = io.internal_encoding
					@read_buffer.force_encoding(encoding)
					@write_buffer.force_encoding(encoding)
				end
			end
			
			attr :io
			
			# The "sync mode" of the stream
			#
			# See IO#sync for full details.
			attr_accessor :sync
			
			# Reads +size+ bytes from the stream.  If +buf+ is provided it must
			# reference a string which will receive the data.
			#
			# See IO#read for full details.
			def read(size=nil, buf=nil)
				if size == 0
					if buf
						buf.clear
						return buf
					else
						return ""
					end
				end

				until @eof
					break if size && size <= @read_buffer.size
					fill_rbuff
					break unless size
				end

				ret = consume_rbuff(size) || ""

				if buf
					buf.replace(ret)
					ret = buf
				end

				(size && ret.empty?) ? nil : ret
			end

			# System write via the nonblocking subsystem
			def write(buffer)
				length = string.length
				total_written = 0

				remaining = buffer.dup

				while total_written < length
					written = @io.write(remaining)
					total_written += written
					
					# TODO ugly
					remaining.slice!(0, written) if written < remaining.length
				end

				total_written
			end

			# Reads at most +maxlen+ bytes from the stream.  If +buf+ is provided it
			# must reference a string which will receive the data.
			#
			# See IO#readpartial for full details.
			def readpartial(maxlen, buf=nil)
				if maxlen == 0
					if buf
						buf.clear
						return buf
					else
						return ""
					end
				end

				if @read_buffer.empty?
					begin
						return sysread(maxlen, buf)
					rescue Errno::EAGAIN
						retry
					end
				end

				ret = consume_rbuff(maxlen)

				if buf
					buf.replace(ret)
					ret = buf
				end

				raise EOFError if ret.empty?
				ret
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
			def gets(eol=@eol, limit=nil)
				idx = @read_buffer.index(eol)
				
				until @eof
					break if idx
					fill_rbuff
					idx = @read_buffer.index(eol)
				end

				if eol.is_a?(Regexp)
					size = idx ? idx+$&.size : nil
				else
					size = idx ? idx+eol.size : nil
				end

				if limit and limit >= 0
					size = [size, limit].min
				end

				consume_rbuff(size)
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

			# Pushes character +c+ back onto the stream such that a subsequent buffered
			# character read will return it.
			#
			# Unlike IO#getc multiple bytes may be pushed back onto the stream.
			#
			# Has no effect on unbuffered reads (such as #sysread).
			def ungetc(c)
				@read_buffer[0,0] = c.chr
			end

			# Returns true if the stream is at file which means there is no more data to
			# be read.
			def eof?
				fill_rbuff if !@eof && @read_buffer.empty?
				
				@eof && @read_buffer.empty?
			end
			alias eof eof?

			# Writes +s+ to the stream.  If the argument is not a string it will be
			# converted using String#to_s.  Returns the number of bytes written.
			def write(object)
				string = object.to_s
				
				append_wbuff(string)
				
				return string.bytesize
			end

			# Writes +s+ to the stream.
			def <<(string)
				append_wbuff(string)
				
				return self
			end

			# Writes +args+ to the stream along with a record separator.
			#
			# See IO#puts for full details.
			def puts(*args, eol: @eol)
				if args.empty?
					append_wbuff(eol)
				else
					args.each do |arg|
						string = arg.to_s
						if string.end_with? eol
							append_wbuff(string)
						else
							append_wbuff(string)
							append_wbuff(eol)
						end
					end
				end
				
				return nil
			end

			# Writes +args+ to the stream.
			#
			# See IO#print for full details.
			def print(*args)
				args.each do |arg|
					append_wbuff(arg.to_s)
				end
				
				return nil
			end

			# Formats and writes to the stream converting parameters under control of
			# the format string.
			#
			# See Kernel#sprintf for format string details.
			def printf(s, *args)
				append_wbuff(s % args)
				
				return nil
			end

			# Flushes buffered data to the stream.
			def flush
				remaining = @write_buffer.length
				written = 0
				
				while remaining > 0
					wrote = @io.write(@write_buffer[written, remaining])
					
					remaining -= wrote
					written += wrote
				end

				@write_buffer[0, written] = ""
			end

			# Closes the stream and flushes any unwritten data.
			def close
				flush rescue nil
				
				@io.close
			end

			private

			# Fills the buffer from the underlying stream
			def fill_rbuff
				if buffer = @io.read(@block_size)
					@read_buffer << buffer
				else
					@eof = true
				end
			end

			# Consumes +size+ bytes from the buffer.
			def consume_rbuff(size = nil)
				# If we are at eof, and the read buffer is empty, we can't consume anything.
				return nil if @eof && @read_buffer.empty?
				
				result = nil
				
				if size == nil || size == @read_buffer.size
					# Consume the entire read buffer:
					result = @read_buffer.dup
					@read_buffer.clear
				else
					# Consume only part of the read buffer:
					result = @read_buffer[0, size]
					@read_buffer[0, size] = ""
				end
				
				return result
			end

			# Writes `string` to the buffer. When the buffer is full or #sync is true the
			# buffer is flushed to the underlying `io`.
			# @param string the string to write to the buffer.
			# @return the number of bytes appended to the buffer.
			def append_wbuff(string)
				@write_buffer << string
				
				if @sync || @write_buffer.bytesize > @block_size
					flush
				end
				
				return string.bytesize
			end
		end
	end
end
