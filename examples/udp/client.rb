#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'async'
require 'async/io'

endpoint = Async::IO::Endpoint.udp("localhost", 5678)

Async do |task|
	endpoint.connect do |socket|
		socket.send("Hello World")
		pp socket.recv(1024)
	end
end
