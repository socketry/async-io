# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2018, by Thibaut Girka.
# Copyright, 2022, by Hal Brodigan.

require 'socket'
require 'async/task'

require_relative 'peer'
require_relative 'server'
require_relative 'generic'

module Async
	module IO
		class BasicSocket < Generic
			wraps ::BasicSocket, :setsockopt, :connect_address, :close_read, :close_write, :local_address, :remote_address, :do_not_reverse_lookup, :do_not_reverse_lookup=, :shutdown, :getsockopt, :getsockname, :getpeername, :getpeereid
			
			wrap_blocking_method :recv, :recv_nonblock
			wrap_blocking_method :recvmsg, :recvmsg_nonblock
			
			wrap_blocking_method :sendmsg, :sendmsg_nonblock
			wrap_blocking_method :send, :sendmsg_nonblock, invert: false
			
			include Peer
		end
		
		class Socket < BasicSocket
			wraps ::Socket, :bind, :ipv6only!, :listen
			
			wrap_blocking_method :recvfrom, :recvfrom_nonblock
			
			# @raise Errno::EAGAIN the connection failed due to the remote end being overloaded.
			def connect(*args)
				begin
					async_send(:connect_nonblock, *args)
				rescue Errno::EISCONN
					# We are now connected.
				end
			end
			
			alias connect_nonblock connect
			
			# @param timeout [Numeric] the maximum time to wait for accepting a connection, if specified.
			def accept(timeout: nil, task: Task.current)
				peer, address = async_send(:accept_nonblock, timeout: timeout)
				wrapper = Socket.new(peer, task.reactor)
				
				wrapper.timeout = self.timeout
				
				return wrapper, address unless block_given?
				
				task.async do |task|
					task.annotate "incoming connection #{address.inspect} [fd=#{wrapper.fileno}]"
					
					begin
						yield wrapper, address
					ensure
						wrapper.close
					end
				end
			end
			
			alias accept_nonblock accept
			alias sysaccept accept
			
			# Build and wrap the underlying io.
			# @option reuse_port [Boolean] Allow this port to be bound in multiple processes.
			# @option reuse_address [Boolean] Allow this port to be bound in multiple processes.
			def self.build(*args, timeout: nil, reuse_address: true, reuse_port: nil, linger: nil, task: Task.current)
				socket = wrapped_klass.new(*args)
				
				if reuse_address
					socket.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
				end
				
				if reuse_port
					socket.setsockopt(SOL_SOCKET, SO_REUSEPORT, 1)
				end
				
				if linger
					socket.setsockopt(SOL_SOCKET, SO_LINGER, linger)
				end
				
				yield socket
				
				wrapper = self.new(socket, task.reactor)
				wrapper.timeout = timeout
				
				return wrapper
			rescue Exception
				socket.close if socket
				
				raise
			end
			
			# Establish a connection to a given `remote_address`.
			# @example
			#  socket = Async::IO::Socket.connect(Async::IO::Address.tcp("8.8.8.8", 53))
			# @param remote_address [Address] The remote address to connect to.
			# @option local_address [Address] The local address to bind to before connecting.
			def self.connect(remote_address, local_address: nil, task: Task.current, **options)
				Console.logger.debug(self) {"Connecting to #{remote_address.inspect}"}
				
				task.annotate "connecting to #{remote_address.inspect}"
				
				wrapper = build(remote_address.afamily, remote_address.socktype, remote_address.protocol, **options) do |socket|
					if local_address
						if defined?(IP_BIND_ADDRESS_NO_PORT)
							# Inform the kernel (Linux 4.2+) to not reserve an ephemeral port when using bind(2) with a port number of 0. The port will later be automatically chosen at connect(2) time, in a way that allows sharing a source port as long as the 4-tuple is unique.
							socket.setsockopt(SOL_IP, IP_BIND_ADDRESS_NO_PORT, 1)
						end
						
						socket.bind(local_address.to_sockaddr)
					end
				end
				
				begin
					wrapper.connect(remote_address.to_sockaddr)
					task.annotate "connected to #{remote_address.inspect} [fd=#{wrapper.fileno}]"
				rescue Exception
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
			def self.bind(local_address, protocol: 0, task: Task.current, **options, &block)
				Console.logger.debug(self) {"Binding to #{local_address.inspect}"}
				
				wrapper = build(local_address.afamily, local_address.socktype, protocol, **options) do |socket|
					socket.bind(local_address.to_sockaddr)
				end
				
				return wrapper unless block_given?
				
				task.async do |task|
					task.annotate "binding to #{wrapper.local_address.inspect}"
					
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
