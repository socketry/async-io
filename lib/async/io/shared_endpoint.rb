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

require_relative 'endpoint'
require_relative 'composite_endpoint'

module Async
	module IO
		# Pre-connect and pre-bind sockets so that it can be used between processes.
		class SharedEndpoint < Endpoint
			# Create a new `SharedEndpoint` by binding to the given endpoint.
			def self.bound(endpoint, backlog: Socket::SOMAXCONN, close_on_exec: false)
				wrappers = endpoint.bound do |server|
					# This is somewhat optional. We want to have a generic interface as much as possible so that users of this interface can just call it without knowing a lot of internal details. Therefore, we ignore errors here if it's because the underlying socket does not support the operation.
					begin
						server.listen(backlog)
					rescue Errno::EOPNOTSUPP
						# Ignore.
					end
					
					server.close_on_exec = close_on_exec
					server.reactor = nil
				end
				
				return self.new(endpoint, wrappers)
			end
			
			# Create a new `SharedEndpoint` by connecting to the given endpoint.
			def self.connected(endpoint, close_on_exec: false)
				wrapper = endpoint.connect
				
				wrapper.close_on_exec = close_on_exec
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
			
			def local_address_endpoint(**options)
				endpoints = @wrappers.map do |wrapper|
					AddressEndpoint.new(wrapper.to_io.local_address)
				end
				
				return CompositeEndpoint.new(endpoints, **options)
			end
			
			def remote_address_endpoint(**options)
				endpoints = @wrappers.map do |wrapper|
					AddressEndpoint.new(wrapper.to_io.remote_address)
				end
				
				return CompositeEndpoint.new(endpoints, **options)
			end
			
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
