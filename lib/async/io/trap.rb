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

module Async
	module IO
		# A cross-reactor/process notification pipe.
		class Trap
			def initialize(name)
				@name = name
				@notifications = []
			end
			
			def install!
				Signal.trap(@name, &self.method(:trigger))
				
				return self
			end
			
			# Block the calling task until the signal occurs.
			def trap
				notification = Notification.new
				@notifications << notification
				
				while true
					notification.wait
					yield
				end
			ensure
				if notification
					notification.close
					@notifications.delete(notification)
				end
			end
			
			# Signal all waiting tasks that the trap occurred.
			# @return [void]
			def trigger
				@notifications.each(&:signal)
			end
		end
	end
end
