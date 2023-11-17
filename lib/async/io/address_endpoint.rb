# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'endpoint'
require 'io/endpoint/address_endpoint'

module Async
	module IO
		AddressEndpoint = ::IO::Endpoint::AddressEndpoint
	end
end
