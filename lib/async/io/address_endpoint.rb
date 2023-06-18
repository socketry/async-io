# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'endpoint'

module Async
	module IO
		# This class will open and close the socket automatically.
		class AddressEndpoint < Endpoint
			def initialize(address, **options)
				super(**options)
				
				@address = address
			end
			
			def to_s
				"\#<#{self.class} #{@address.inspect}>"
			end
			
			attr :address
			
			# Bind a socket to the given address. If a block is given, the socket will be automatically closed when the block exits.
			# @yield [Socket] the bound socket
			# @return [Socket] the bound socket
			def bind(&block)
				Socket.bind(@address, **@options, &block)
			end
			
			# Connects a socket to the given address. If a block is given, the socket will be automatically closed when the block exits.
			# @return [Socket] the connected socket
			def connect(&block)
				Socket.connect(@address, **@options, &block)
			end
		end
	end
end
