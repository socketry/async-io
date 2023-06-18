# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative '../stream'

module Async
	module IO
		module Protocol
			class Generic
				def initialize(stream)
					@stream = stream
				end
				
				def closed?
					@stream.closed?
				end
				
				def close
					@stream.close
				end
				
				attr :stream
			end
		end
	end
end
