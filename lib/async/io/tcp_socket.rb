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
			wraps ::TCPSocket, :gets, :puts
			
			def initialize(remote_host, remote_port = nil, local_host = nil, local_port = nil)
				if remote_host.is_a? ::TCPSocket
					super(remote_host)
				else
					super(::TCPSocket.new(remote_host, remote_port, local_host, local_port))
				end
			end
			
			class << self
				alias open new
			end
			
			include Peer
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
