# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require_relative 'socket'

module Async
	module IO
		# Asynchronous UDP socket wrapper.
		class UDPSocket < IPSocket
			wraps ::UDPSocket, :bind
			
			def initialize(family)
				if family.is_a? ::UDPSocket
					super(family)
				else
					super(::UDPSocket.new(family))
				end
			end
			
			# We pass `send` through directly, but in theory it might block. Internally, it uses sendto.
			def_delegators :@io, :send, :connect
			
			# This function is so fucked. Why does `UDPSocket#recvfrom` return the remote address as an array, but `Socket#recfrom` return it as an `Addrinfo`? You should prefer `recvmsg`.
			wrap_blocking_method :recvfrom, :recvfrom_nonblock
		end
	end
end
