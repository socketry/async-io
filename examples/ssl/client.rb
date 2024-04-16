#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Hal Brodigan.

require 'async'
require 'async/io'
require 'async/io/stream'

endpoint = Async::IO::Endpoint.ssl('localhost',5678)

Async do |async|
	endpoint.connect do |socket|
		stream = Async::IO::Stream.new(socket)

		(1..).each do |i|
			stream.puts "test #{i}"
			puts stream.gets
			sleep 1
		end
	end
end
