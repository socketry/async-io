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

require_relative 'endpoint'

module Async
	module IO
		# Pre-connect and pre-bind sockets so that it can be used between processes.
		class SharedEndpoint < Endpoint
			# Create a new `SharedEndpoint` by binding to the given endpoint.
			def self.bound(endpoint, backlog = Socket::SOMAXCONN)
				wrappers = endpoint.bound do |server|
					server.listen(backlog)
					server.close_on_exec = false
					server.reactor = nil
				end
				
				return self.new(endpoint, wrappers)
			end
			
			# Create a new `SharedEndpoint` by connecting to the given endpoint.
			def self.connected(endpoint)
				wrapper = endpoint.connect
				
				wrapper.close_on_exec = false
				wrapper.reactor = nil
				
				return self.new(endpoint, [wrapper])
			end
			
			def initialize(endpoint, wrappers, **options)
				super(**options)
				
				@endpoint = endpoint
				@wrappers = wrappers
			end
			
			attr :endpoint
			attr :wrappers
			
			# Close all the internal wrappers.
			def close
				@wrappers.each(&:close)
				@wrappers.clear
			end
			
			def bind
				task = Async::Task.current
				
				@wrappers.each do |server|
					server = server.dup
					
					task.async do |task|
						task.annotate "binding to #{server.inspect}"
						
						begin
							yield server, task
						ensure
							server.close
						end
					end
				end
			end
			
			def connect
				task = Async::Task.current
				
				@wrappers.each do |peer|
					peer = peer.dup
					
					task.async do |task|
						task.annotate "connected to #{peer.inspect} [#{peer.fileno}]"
						
						begin
							yield peer, task
						ensure
							peer.close
						end
					end
				end
			end
			
			def accept(backlog = nil, &block)
				bind do |server|
					server.accept_each(&block)
				end
			end
			
			def to_s
				"\#<#{self.class} #{@wrappers.size} descriptors for #{@endpoint}>"
			end
		end
	end
end
