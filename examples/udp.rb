#!/usr/bin/env ruby

require 'async'
require_relative '../lib/async/io'

endpoint = Async::IO::Endpoint.udp("localhost", 5300)

Async do |task|
	endpoint.bind do |socket|
		# This block executes for both IPv4 and IPv6 UDP sockets:
		loop do
			data, address = socket.recvfrom(1024)
			pp data
			pp address
		end
	end
	
	# This will try connecting to all addresses and yield for the first one that successfully connects:
	endpoint.connect do |socket|
		loop do
			task.sleep rand(1..10)
			socket.send "Hello World!", 0
		end
	end
end

