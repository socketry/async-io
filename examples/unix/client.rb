#!/usr/bin/env ruby

require "socket"

10.times do
	UNIXSocket.open("./tmp.sock") do |socket|
		socket << "hello\n"
		p socket.read(6)
		socket.close
	end
end
