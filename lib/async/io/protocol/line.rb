# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

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
