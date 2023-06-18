# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2019, by Olle Jonsson.

require_relative 'endpoint'
require 'io/endpoint/unix_endpoint'

module Async
	module IO
		UNIXEndpoint = ::IO::Endpoint::UNIXEndpoint
	end
end
