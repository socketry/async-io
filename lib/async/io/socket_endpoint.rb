# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'endpoint'

module Async
	module IO
		# This class doesn't exert ownership over the specified socket, wraps a native ::IO.
		class SocketEndpoint < Endpoint
			def initialize(socket, **options)
				super(**options)
				
				# This socket should already be in the required state.
				@socket = Async::IO.try_convert(socket)
			end
			
			def to_s
				"\#<#{self.class} #{@socket.inspect}>"
			end
			
			attr :socket
			
			def bind(&block)
				if block_given?
					begin
						yield @socket
					ensure
						@socket.reactor = nil
					end
				else
					return @socket
				end
			end
			
			def connect(&block)
				if block_given?
					begin
						yield @socket
					ensure
						@socket.reactor = nil
					end
				else
					return @socket
				end
			end
		end
		
		class Endpoint
			def self.socket(socket, **options)
				SocketEndpoint.new(socket, **options)
			end
		end
	end
end
