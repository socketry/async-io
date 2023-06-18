# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require_relative 'notification'

module Async
	module IO
		class Threads
			def initialize(parent: nil)
				@parent = parent
			end
			
			def async(parent: (@parent or Task.current))
				parent.async do
					thread = ::Thread.new do
						yield
					end
					
					thread.join
				rescue Stop
					if thread&.alive?
						thread.raise(Stop)
					end
					
					begin
						thread.join
					rescue Stop
						# Ignore.
					end
				end
			end
		end
	end
end
