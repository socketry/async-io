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
require_relative 'generic'

module Async
	module IO
		class BasicSocket < Generic
			wraps ::BasicSocket, :setsockopt, :connect_address, :local_address, :remote_address, :do_not_reverse_lookup, :do_not_reverse_lookup=, :shutdown, :getsockopt, :getsockname, :getpeername, :getpeereid
			
			wrap_blocking_method :recv, :recv_nonblock
			wrap_blocking_method :recvmsg, :recvmsg_nonblock
			
			wrap_blocking_method :recvfrom, :recvfrom_nonblock
			
			wrap_blocking_method :sendmsg, :sendmsg_nonblock
			wrap_blocking_method :send, :sendmsg_nonblock, invert: false
		end
		
		module ServerSocket
			def accept
				peer, address = async_send(:accept_nonblock)
				
				if block_given?
					wrapper = Socket.new(peer, self.reactor)
					
					begin
						yield wrapper, address
					ensure
						wrapper.close
					end
				else
					return Socket.new(peer, self.reactor), address
				end
			end
			
			def accept_each(task: Task.current)
				task.annotate "accepting connections #{self.local_address.inspect}"
				
				while true
					task.async(*self.accept) do |task, io, address|
						task.annotate "incoming connection #{address}"
						
						begin
							yield io, address
						ensure
							io.close
						end
					end
				end
			end
		end
		
		class Socket < BasicSocket
			wraps ::Socket, :bind, :ipv6only!, :listen
			
			include ::Socket::Constants
			
			include ServerSocket
			
			def connect(*args)
				begin
					async_send(:connect_nonblock, *args)
				rescue Errno::EISCONN
					# We are now connected.
				end
			end
			
			# Establish a connection to a given `remote_address`.
			# @example
			#  socket = Async::IO::Socket.connect(Async::IO::Address.tcp("8.8.8.8", 53))
			# @param remote_address [Addrinfo] The remote address to connect to.
			# @param local_address [Addrinfo] The local address to bind to before connecting.
			# @option protcol [Integer] The socket protocol to use.
			def self.connect(remote_address, local_address = nil, protocol: 0, task: Task.current)
				task.annotate "connecting to #{remote_address.inspect}"
				
				socket = ::Socket.new(remote_address.afamily, remote_address.socktype, protocol)
				
				if local_address
					socket.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_REUSEADDR, true)
					socket.bind(local_address.to_sockaddr) if local_address
				end
				
				wrapper = self.new(socket, task.reactor)
				wrapper.connect(remote_address.to_sockaddr)
				
				task.annotate "connected to #{remote_address.inspect}"
				
				if block_given?
					begin
						return yield(wrapper)
					ensure
						wrapper.close
					end
				else
					return wrapper
				end
			end
			
			# Bind to a local address.
			# @example
			#  socket = Async::IO::Socket.bind(Async::IO::Address.tcp("0.0.0.0", 9090))
			# @param local_address [Address] The local address to bind to.
			# @option protocol [Integer] The socket protocol to use.
			# @option reuse_port [Boolean] Allow this port to be bound in multiple processes.
			def self.bind(local_address, protocol: 0, reuse_port: false, task: Task.current, &block)
				task.annotate "binding to #{local_address.inspect}"
				
				socket = ::Socket.new(local_address.afamily, local_address.socktype, protocol)
				
				socket.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_REUSEADDR, true)
				socket.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_REUSEPORT, true) if reuse_port
				socket.bind(local_address.to_sockaddr)
				
				wrapper = self.new(socket, task.reactor)
				
				if block_given?
					begin
						return yield(wrapper, task)
					ensure
						wrapper.close
					end
				else
					return wrapper
				end
			end
			
			# Bind to a local address and accept connections in a loop.
			def self.accept(*args, backlog: SOMAXCONN, &block)
				bind(*args) do |server, task|
					server.listen(backlog) if backlog
					
					server.accept_each(task: task, &block)
				end
			end
		end
		
		class IPSocket < BasicSocket
			wraps ::IPSocket, :addr, :peeraddr
		end
	end
end
