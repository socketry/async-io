# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'notification'

require 'thread'

module Async
	module IO
		# A cross-reactor/process notification pipe.
		class Trap
			def initialize(name)
				@name = name
				@notifications = []
				
				@installed = false
				@mutex = Mutex.new
			end
			
			def to_s
				"\#<#{self.class} #{@name}>"
			end
			
			# Ignore the trap within the current process. Can be invoked before forking and/or invoking `install!` to assert default behaviour.
			def ignore!
				Signal.trap(@name, :IGNORE)
			end
			
			def default!
				Signal.trap(@name, :DEFAULT)
			end
			
			# Install the trap into the current process. Thread safe.
			# @return [Boolean] whether the trap was installed or not. If the trap was already installed, returns nil.
			def install!
				return if @installed
				
				@mutex.synchronize do
					return if @installed
					
					Signal.trap(@name, &self.method(:trigger))
					
					@installed = true
				end
				
				return true
			end
			
			# Wait until the signal occurs. If a block is given, execute in a loop.
			# @yield [Async::Task] the current task.
			def wait(task: Task.current, &block)
				task.annotate("waiting for signal #{@name}")
				
				notification = Notification.new
				@notifications << notification
				
				if block_given?
					while true
						notification.wait
						yield task
					end
				else
					notification.wait
				end
			ensure
				if notification
					notification.close
					@notifications.delete(notification)
				end
			end
			
			# Deprecated.
			alias trap wait
			
			# In order to avoid blocking the reactor, specify `transient: true` as an option.
			def async(parent: Task.current, **options, &block)
				parent.async(**options) do |task|
					self.wait(task: task, &block)
				end
			end
			
			# Signal all waiting tasks that the trap occurred.
			# @return [void]
			def trigger(signal_number = nil)
				@notifications.each(&:signal)
			end
		end
	end
end
