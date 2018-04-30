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
			wraps ::BasicSocket, :setsockopt, :connect_address, :close_read, :close_write, :local_address, :remote_address, :do_not_reverse_lookup, :do_not_reverse_lookup=, :shutdown, :getsockopt, :getsockname, :getpeername, :getpeereid
			
			wrap_blocking_method :recv, :recv_nonblock
			wrap_blocking_method :recvmsg, :recvmsg_nonblock
			
			wrap_blocking_method :sendmsg, :sendmsg_nonblock
			wrap_blocking_method :send, :sendmsg_nonblock, invert: false
			
			def type
				self.local_address.socktype
			end
		end
		
		module Server
			def accept_each(task: Task.current)
				task.annotate "accepting connections #{self.local_address.inspect}"
				
				while true
					self.accept(task: task) do |io, address|
						yield io, address, task: task
					end
				end
			end
		end
		
		class Socket < BasicSocket
			wraps ::Socket, :bind, :ipv6only!, :listen
			
			wrap_blocking_method :recvfrom, :recvfrom_nonblock
			
			include ::Socket::Constants
			
			def connect(*args)
				begin
					async_send(:connect_nonblock, *args)
				rescue Errno::EISCONN
					# We are now connected.
				end
			end
			
			alias connect_nonblock connect
			
			def accept(task: Task.current)
				peer, address = async_send(:accept_nonblock)
				wrapper = Socket.new(peer, task.reactor)
				
				return wrapper, address unless block_given?
				
				task.async do |task|
					task.annotate "incoming connection #{address.inspect}"
					
					begin
						yield wrapper, address
					rescue
						Async.logger.error(self) {$!}
					ensure
						wrapper.close
					end
				end
			end
			
			alias accept_nonblock accept
			alias sysaccept accept
			
			def self.build(*args, task: Task.current)
				socket = wrapped_klass.new(*args)
				
				yield socket
				
				return self.new(socket, task.reactor)
			rescue Exception
				socket.close if socket
				
				raise
			end
			
			# Establish a connection to a given `remote_address`.
			# @example
			#  socket = Async::IO::Socket.connect(Async::IO::Address.tcp("8.8.8.8", 53))
			# @param remote_address [Addrinfo] The remote address to connect to.
			# @param local_address [Addrinfo] The local address to bind to before connecting.
			# @option protcol [Integer] The socket protocol to use.
			def self.connect(remote_address, local_address = nil, reuse_port: false, task: Task.current, **options)
				# Async.logger.debug(self) {"Connecting to #{remote_address.inspect}"}
				
				task.annotate "connecting to #{remote_address.inspect}"
				
				wrapper = build(remote_address.afamily, remote_address.socktype, remote_address.protocol, **options) do |socket|
					socket.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_REUSEADDR, reuse_port)
					
					if local_address
						socket.bind(local_address.to_sockaddr)
					end

					self.new(socket, task.reactor)
				end
				
				begin
					wrapper.connect(remote_address.to_sockaddr)
					task.annotate "connected to #{remote_address.inspect}"
				rescue
					wrapper.close
					raise
				end
				
				return wrapper unless block_given?
				
				begin
					yield wrapper, task
				ensure
					wrapper.close
				end
			end
			
			# Bind to a local address.
			# @example
			#  socket = Async::IO::Socket.bind(Async::IO::Address.tcp("0.0.0.0", 9090))
			# @param local_address [Address] The local address to bind to.
			# @option protocol [Integer] The socket protocol to use.
			# @option reuse_port [Boolean] Allow this port to be bound in multiple processes.
			def self.bind(local_address, protocol: 0, reuse_port: false, task: Task.current, **options, &block)
				Async.logger.debug(self) {"Binding to #{local_address.inspect}"}
				
				wrapper = build(local_address.afamily, local_address.socktype, protocol, **options) do |socket|
					socket.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_REUSEADDR, true)
					socket.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_REUSEPORT, true) if reuse_port
					socket.bind(local_address.to_sockaddr)
				end
				
				return wrapper unless block_given?
				
				task.async do |task|
					task.annotate "binding to #{local_address.inspect}"
					
					begin
						yield wrapper, task
					ensure
						wrapper.close
					end
				end
			end
			
			# Bind to a local address and accept connections in a loop.
			def self.accept(*args, backlog: SOMAXCONN, &block)
				bind(*args) do |server, task|
					server.listen(backlog) if backlog
					
					server.accept_each(task: task, &block)
				end
			end
			
			include Server
			
			def self.pair(*args)
				::Socket.pair(*args).map(&self.method(:new))
			end
		end
		
		class IPSocket < BasicSocket
			wraps ::IPSocket, :addr, :peeraddr
			
			wrap_blocking_method :recvfrom, :recvfrom_nonblock
		end
	end
end
