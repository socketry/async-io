# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require_relative 'socket'

module Async
	module IO
		class UNIXSocket < BasicSocket
			# `send_io`, `recv_io` and `recvfrom` may block but no non-blocking implementation available.
			wraps ::UNIXSocket, :path, :addr, :peeraddr, :send_io, :recv_io, :recvfrom
			
			include Peer
		end
		
		class UNIXServer < UNIXSocket
			wraps ::UNIXServer, :listen
			
			def accept
				peer = async_send(:accept_nonblock)
				wrapper = UNIXSocket.new(peer, self.reactor)
				
				return wrapper unless block_given?
				
				begin
					yield wrapper
				ensure
					wrapper.close
				end
			end
			
			alias sysaccept accept
			alias accept_nonblock accept
		end
	end
end
