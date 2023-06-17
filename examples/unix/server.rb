#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'async/io'
require 'async/io/unix_endpoint'

@server = Async::IO::Endpoint.unix("./tmp.sock")

Async do |task|
	@server.accept do |client|
		Console.logger.info(client, "Accepted connection")
		a = client.read(6)
		sleep 1
		client.send "elloh\n"
		client.close_write
	end
end
