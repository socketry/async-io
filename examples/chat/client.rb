#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../../lib", __dir__)

require 'async/reactor'
require 'async/io/stream'
require 'async/io/host_endpoint'
require 'async/io/protocol/line'

class User < Async::IO::Protocol::Line
end

endpoint = Async::IO::Endpoint.parse(ARGV.pop || "tcp://localhost:7138")

input = Async::IO::Protocol::Line.new(
	Async::IO::Stream.new(
		Async::IO::Generic.new($stdin)
	)
)

Async::Reactor.run do |task|
	socket = endpoint.connect
	stream = Async::IO::Stream.new(socket)
	user = User.new(stream)
	
	connection = task.async do
		while line = user.read_line
			puts line
		end
	end
	
	while line = input.read_line
		user.write_lines line
	end
rescue EOFError
	# It's okay, we are disconnecting, because stdin has closed.
ensure
	connection.stop
	user.close
end
