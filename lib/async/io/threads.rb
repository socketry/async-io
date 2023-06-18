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
			
			if Async::Scheduler.supported?
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
			else
				def async(parent: (@parent or Task.current))
					parent.async do |task|
						notification = Async::IO::Notification.new
						
						thread = ::Thread.new do
							yield
						ensure
							notification.signal
						end
						
						task.annotate "Waiting for thread to finish..."
						
						notification.wait
						
						thread.value
					ensure
						if thread&.alive?
							thread.raise(Stop)
							
							begin
								thread.join
							rescue Stop
								# Ignore.
							end
						end
						
						notification&.close
					end
				end
			end
		end
	end
end
