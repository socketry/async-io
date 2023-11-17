# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'generic'

module Async
	module IO
		# A cross-reactor/process notification pipe.
		class Notification
			def initialize
				@input, @output = ::IO.pipe
			end
			
			def close
				@input.close
				@output.close
			end
			
			# Wait for signal to be called.
			# @return [Object]
			def wait
				@input.read(1)
			end
			
			# Signal to a given task that it should resume operations.
			# @return [void]
			def signal
				@output.write(".")
			end
		end
	end
end
