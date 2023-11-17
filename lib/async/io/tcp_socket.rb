# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2018, by Jiang Jinyang.

require_relative 'socket'
require_relative 'stream'

module Async
	module IO
		TCPSocket = ::TCPSocket
		TCPSocket.prepend(Peer)
		
		TCPServer = ::TCPServer
		TCPServer.prepend(Server)
		
		# Server accept with timeout?
		# def accept(timeout: nil, task: Task.current)
	end
end
