# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'socket'

require 'openssl'

module Async
	module IO
		SSLError = OpenSSL::SSL::SSLError
		SSLSocket = ::OpenSSL::SSL::SSLSocket
		SSLSocket.prepend(Peer)
		
		SSLServer = ::OpenSSL::SSL::SSLServer
		SSLServer.prepend(Server)
	end
end
