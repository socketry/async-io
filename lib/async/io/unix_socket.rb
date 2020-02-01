# frozen_string_literal: true

# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
