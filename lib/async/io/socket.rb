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
		BasicSocket = ::BasicSocket
		BasicSocket.prepend(Peer)
		
		Socket = ::Socket
		Socket.prepend(Server)
		
		IPSocket = ::IPSocket
	end
end
