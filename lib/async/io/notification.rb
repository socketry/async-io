# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'generic'

module Async
	module IO
		# A cross-reactor/process notification pipe.
		class Notification
			def initialize
				pipe = ::IO.pipe
				
				# We could call wait and signal from different reactors/threads/processes, so we don't create wrappers here, because they are not thread safe by design.
				@input = pipe.first
				@output = pipe.last
			end
			
			def close
				@input.close
				@output.close
			end
			
			# Wait for signal to be called.
			# @return [Object]
			def wait
				wrapper = Async::IO::Generic.new(@input)
				wrapper.read(1)
			ensure
				# Remove the wrapper from the reactor.
				wrapper.reactor = nil
			end
			
			# Signal to a given task that it should resume operations.
			# @return [void]
			def signal
				wrapper = Async::IO::Generic.new(@output)
				wrapper.write(".")
			ensure
				wrapper.reactor = nil
			end
		end
	end
end
