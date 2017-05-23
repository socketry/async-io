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

require_relative '../socket'

module Async
	module IO
		module Wrap
			module TCPServer
				def self.new(*args)
					case args.size
					when 2
						local_address = Addrinfo.tcp(*args)
					when 1
						local_address = Addrinfo.tcp("0.0.0.0", *args)
					else
						raise ArgumentError, "TCPServer.new([hostname], port)"
					end
					
					return Async::IO::Socket.bind(local_address)
				end
			end
			
			module TCPSocket
				def self.new(remote_host, remote_port, local_host=nil, local_port=nil)
					remote_address = Addrinfo.tcp(remote_host, remote_port)
					
					if local_host && local_port
						local_address = Addrinfo.tcp(local_host, local_port)
					end
					
					return Async::IO::Socket.connect(remote_address, local_address)
				end
				
				def self.open(*args)
					self.new(*args)
				end
			end
		end
	end
end
