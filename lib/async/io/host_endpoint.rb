# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2019, by Olle Jonsson.
# Copyright, 2020, by Benoit Daloze.

require_relative 'endpoint'
require 'io/endpoint/host_endpoint'

module Async
	module IO
		HostEndpoint = ::IO::Endpoint::HostEndpoint
	end
end
