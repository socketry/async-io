# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.
# Copyright, 2019, by Olle Jonsson.

require_relative 'endpoint'
require_relative 'composite_endpoint'

module Async
	module IO
		# Pre-connect and pre-bind sockets so that it can be used between processes.
		class SharedEndpoint < Endpoint
			# Create a new `SharedEndpoint` by binding to the given endpoint.
			def self.bound(endpoint, backlog: Socket::SOMAXCONN, close_on_exec: false, **options)
				sockets = Array(endpoint.bind(**options))
				
				wrappers = sockets.each do |server|
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
					# Forward the options to the internal endpoints:
					AddressEndpoint.new(wrapper.to_io.local_address, **options)
				end
				
				return CompositeEndpoint.new(endpoints)
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
					task.async do |task|
						task.annotate "binding to #{server.inspect}"
						yield server, task
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
			
			def accept(backlog = nil, **options, &block)
				bind do |server|
					server.accept_each(**options, &block)
				end
			end
			
			def to_s
				"\#<#{self.class} #{@wrappers.size} descriptors for #{@endpoint}>"
			end
		end
		
		class Endpoint
			def bound(**options)
				SharedEndpoint.bound(self, **options)
			end
			
			def connected(**options)
				SharedEndpoint.connected(self, **options)
			end
		end
	end
end
