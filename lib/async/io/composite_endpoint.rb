# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require_relative 'endpoint'
require 'io/endpoint/composite_endpoint'

module Async
	module IO
		CompositeEndpoint = ::IO::Endpoint::CompositeEndpoint
	end
end
