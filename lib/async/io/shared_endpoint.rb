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
		class SharedEndpoint < Endpoint
			def self.bound(endpoint, backlog = Socket::SOMAXCONN)
				wrappers = []
				
				endpoint.each do |singular_endpoint|
					server = singular_endpoint.bind
					
					server.listen(backlog)
					
					server.close_on_exec = false
					server.reactor = nil
					
					wrappers << server
				end
				
				self.new(endpoint, wrappers)
			end
			
			def self.connected(endpoint)
				peer = endpoint.connect
				
				peer.close_on_exec = false
				peer.reactor = nil
				
				self.new(endpoint, [peer])
			end
			
			def initialize(endpoint, wrappers, **options)
				super(**options)
				
				@endpoint = endpoint
				@wrappers = wrappers
			end
			
			attr :endpoint
			attr :wrappers
			
			def close
				@wrappers.each(&:close)
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
						task.annotate "connected to #{peer.inspect}"
						
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
				"\#<#{self.class} #{@wrappers.count} descriptors for #{@endpoint}>"
			end
		end
	end
end
