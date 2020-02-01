#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require 'async'
require 'async/io/trap'
require 'async/io/host_endpoint'
require 'async/io/stream'

endpoint = Async::IO::Endpoint.tcp('localhost', 4578)

Async do |task|
	endpoint.connect do |peer|
		stream = Async::IO::Stream.new(peer)
		
		while true
			task.sleep 1
			stream.puts "Hello World!"
			puts stream.gets.inspect
		end
	end
end
