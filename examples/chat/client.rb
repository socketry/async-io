#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../../lib", __dir__)

require 'async'
require 'async/notification'
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

Async do |task|
	socket = endpoint.connect
	stream = Async::IO::Stream.new(socket)
	user = User.new(stream)
	
	# This is used to track whether either reading from stdin failed or reading from network failed.
	finished = Async::Notification.new
	
	# Read lines from stdin and write to network.
	terminal = task.async do
		while line = input.read_line
			user.write_lines line
		end
	rescue EOFError
		# It's okay, we are disconnecting, because stdin has closed.
	ensure
		finished.signal
	end
	
	# Read lines from network and write to stdout.
	network = task.async do
		while line = user.read_line
			puts line
		end
	ensure
		finished.signal
	end
	
	# Wait for any of the above processes to finish:
	finished.wait
ensure
	# Stop all the nested tasks if we are exiting:
	network.stop if network
	terminal.stop if terminal
	user.close if user
end
