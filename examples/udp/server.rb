#!/usr/bin/env ruby

require 'async'
require 'async/io'

endpoint = Async::IO::Endpoint.udp("localhost", 5678)

Async do |task|
	endpoint.bind do |socket|
		while true
			data, address = socket.recvfrom(1024)
			socket.send(data.reverse, 0, address)
		end
	end
end
