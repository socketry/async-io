# frozen_string_literal: true

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

require_relative 'generic'

module Async
	module IO
		module Protocol
			class Line < Generic
				def initialize(stream, eol = $/)
					super(stream)
					
					@eol = eol
				end
				
				attr :eol
				
				def write_lines(*args)
					if args.empty?
						@stream.write(@eol)
					else
						args.each do |arg|
							@stream.write(arg)
							@stream.write(@eol)
						end
					end
					
					@stream.flush
				end
				
				def read_line
					@stream.read_until(@eol) or @stream.eof!
				end
				
				def peek_line
					@stream.peek do |read_buffer|
						if index = read_buffer.index(@eol)
							return read_buffer.slice(0, index)
						end
					end
					
					raise EOFError
				end
				
				def each_line
					return to_enum(:each_line) unless block_given?
					
					while line = @stream.read_until(@eol)
						yield line
					end
				end
				
				def read_lines
					@stream.read.split(@eol)
				end
			end
		end
	end
end
