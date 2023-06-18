# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require_relative 'socket'

module Async
	module IO
		UNIXSocket = ::UNIXSocket
		UNIXServer = ::UNIXServer
	end
end
