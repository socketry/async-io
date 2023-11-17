# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2019, by Olle Jonsson.

require_relative 'endpoint'
require 'io/endpoint/ssl_endpoint'

module Async
	module IO
		SSLEndpoint = ::IO::Endpoint::SSLEndpoint
	end
end
