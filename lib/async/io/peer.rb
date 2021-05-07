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

require 'socket'

module Async
	module IO
		module Peer
			include ::Socket::Constants
			
			# Is it likely that the socket is still connected?
			# May return false positive, but won't return false negative.
			def connected?
				return false if @io.closed?
				
				# If we can wait for the socket to become readable, we know that the socket may still be open.
				result = to_io.recv_nonblock(1, MSG_PEEK, exception: false)
				
				# Either there was some data available, or we can wait to see if there is data avaialble.
				return !result.empty? || result == :wait_readable
				
			rescue Errno::ECONNRESET
				# This might be thrown by recv_nonblock.
				return false
			end
			
			def eof
				!connected?
			end
			
			def eof?
				!connected?
			end
			
			# Best effort to set *_NODELAY if it makes sense. Swallows errors where possible.
			def sync=(value)
				super
				
				case self.protocol
				when 0, IPPROTO_TCP
					self.setsockopt(IPPROTO_TCP, TCP_NODELAY, value ? 1 : 0)
				else
					Console.logger.warn(self) {"Unsure how to sync=#{value} for #{self.protocol}!"}
				end
			rescue Errno::EINVAL
				# On Darwin, sometimes occurs when the connection is not yet fully formed. Empirically, TCP_NODELAY is enabled despite this result.
			rescue Errno::EOPNOTSUPP
				# Some platforms may simply not support the operation.
				# Console.logger.warn(self) {"Unable to set sync=#{value}!"}
			end
			
			def sync
				case self.protocol
				when IPPROTO_TCP
					self.getsockopt(IPPROTO_TCP, TCP_NODELAY).bool
				else
					true
				end && super
			end
			
			def type
				self.local_address.socktype
			end
			
			def protocol
				self.local_address.protocol
			end
		end
	end
end
