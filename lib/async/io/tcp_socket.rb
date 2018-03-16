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
require_relative 'stream'

module Async
	module IO
		# Asynchronous TCP socket wrapper.
		class TCPSocket < IPSocket
			wraps ::TCPSocket
			
			def initialize(remote_host, remote_port = nil, local_host=nil, local_port=nil)
				if remote_host.is_a? ::TCPSocket
					super(remote_host)
				else
					remote_address = Addrinfo.tcp(remote_host, remote_port)
					local_address = Addrinfo.tcp(local_host, local_port) if local_host
					
					socket = Socket.connect(remote_address, local_address)
					
					super(::TCPSocket.for_fd(socket.fileno))
				end
				
				@buffer = Stream.new(self)
			end
			
			def gets(separator = $/)
				@buffer.flush
				
				@buffer.read_until(separator)
			end
			
			def puts(*args, separator: $/)
				args.each do |arg|
					@buffer.write(arg)
					@buffer.write(separator)
				end
			end
			
			def flush
				@buffer.flush
			end
		end
		
		# Asynchronous TCP server wrappper.
		class TCPServer < TCPSocket
			wraps ::TCPServer, :listen
			
			def initialize(*args)
				if args.first.is_a? ::TCPServer
					super(args.first)
				else
					# We assume this operation doesn't block (for long):
					super(::TCPServer.new(*args))
				end
			end
			
			def accept(task: Task.current)
				peer, address = async_send(:accept_nonblock)
				
				wrapper = TCPSocket.new(peer)
				
				return wrapper, address
			end
		end
	end
end
