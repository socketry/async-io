#!/usr/bin/env ruby

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
