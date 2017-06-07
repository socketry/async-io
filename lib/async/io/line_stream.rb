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

require_relative 'stream'

module Async
	module IO
		class LineStream < Stream
			include Enumerable
			
			def initialize(*args, eol: $\, **options)
				super(*args, **options)
				
				@eol = eol
			end
			
			def puts(*args)
				if args.empty?
					@io.write(@eol)
				else
					args.each do |arg|
						@io.write(arg)
						@io.write(@eol)
					end
				end
			end
			
			def gets
				index = @read_buffer.index(@eol)
				
				until index || @eof
					fill_read_buffer
					index = @read_buffer.index(@eol)
				end
				
				if line = consume_read_buffer(index)
					consume_read_buffer(@eol.bytesize)
					
					return line
				end
			end
			
			alias readline gets
			
			def each
				return to_enum unless block_given?
				
				while line = self.gets
					yield line
				end
			end
			
			alias readlines to_a
		end
	end
end
