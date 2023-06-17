# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'generic'

module Async
	module IO
		class StandardInput < Generic
			def initialize(io = $stdin)
				super(io)
			end
		end
		
		class StandardOutput < Generic
			def initialize(io = $stdout)
				super(io)
			end
		end
		
		class StandardError < Generic
			def initialize(io = $stderr)
				super(io)
			end
		end
		
		STDIN = StandardInput.new
		STDOUT = StandardOutput.new
		STDERR = StandardError.new
	end
end
