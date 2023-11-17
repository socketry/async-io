# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'endpoint'
require 'io/endpoint/socket_endpoint'

module Async
	module IO
		SocketEndpoint = ::IO::Endpoint::SocketEndpoint
	end
end
