# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2018, by Jiang Jinyang.

require_relative 'socket'
require_relative 'stream'
require 'fcntl'

module Async
	module IO
		# Asynchronous TCP socket wrapper.
		class TCPSocket < IPSocket
			wraps ::TCPSocket
			
			def initialize(remote_host, remote_port = nil, local_host = nil, local_port = nil)
				if remote_host.is_a? ::TCPSocket
					super(remote_host)
				else
					remote_address = Addrinfo.tcp(remote_host, remote_port)
					local_address = Addrinfo.tcp(local_host, local_port) if local_host
					
					# We do this unusual dance to avoid leaking an "open" socket instance.
					socket = Socket.connect(remote_address, local_address: local_address)
					fd = socket.fcntl(Fcntl::F_DUPFD)
					Console.logger.debug(self) {"Connected to #{remote_address.inspect}: #{fd}"}
					socket.close
					
					super(::TCPSocket.for_fd(fd))
					
					# The equivalent blocking operation. Unfortunately there is no trivial way to make this non-blocking.
					# super(::TCPSocket.new(remote_host, remote_port, local_host, local_port))
				end
				
				@stream = Stream.new(self)
			end
			
			class << self
				alias open new
			end
			
			def close
				@stream.flush
				super
			end
			
			include Peer
			
			attr :stream
			
			# The way this buffering works is pretty atrocious.
			def_delegators :@stream, :gets, :puts
			
			def sysread(size, buffer = nil)
				data = @stream.read_partial(size)
				
				if buffer
					buffer.replace(data)
				end
				
				return data
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
			
			def accept(timeout: nil, task: Task.current)
				peer, address = async_send(:accept_nonblock, timeout: timeout)
				
				wrapper = TCPSocket.new(peer)
				
				wrapper.timeout = self.timeout
				
				return wrapper, address unless block_given?
				
				begin
					yield wrapper, address
				ensure
					wrapper.close
				end
			end
			
			alias accept_nonblock accept
			alias sysaccept accept
			
			include Server
		end
	end
end
