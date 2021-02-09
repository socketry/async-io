# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
