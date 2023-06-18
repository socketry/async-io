# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

module Async
	module IO
		class Buffer < String
			BINARY = Encoding::BINARY
			
			def initialize
				super
				
				force_encoding(BINARY)
			end
			
			def << string
				if string.encoding == BINARY
					super(string)
				else
					super(string.b)
				end
				
				return self
			end
			
			alias concat <<
		end
	end
end
