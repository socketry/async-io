#!/usr/bin/env ruby

require 'async'
require 'async/logger'
require_relative '../lib/async/io/socket'

reactor = Async::Reactor.new
Async.logger.level = Logger::DEBUG

SERVER_ADDRESS = Addrinfo.tcp('localhost', 6777)

REPEATS = 10

timer = reactor.after(1) do
	puts "Reactor timed out!"
	reactor.stop
end

reactor.async do |task|
	# Everything happens sequentially within a single async task.
	Async.logger.info('server') {"Binding server to #{SERVER_ADDRESS.inspect}"}
	
	Async::IO::Socket.bind(SERVER_ADDRESS, backlog: 10) do |server|
		REPEATS.times do |i|
			server.accept do |peer|
				Async.logger.info('server') {"Sending data to peer #{i}"}
				
				peer.write "data #{i}"
			end
		end
	end
	
	Async.logger.info('server') {"Server finished, canceling timer"}
	
	timer.cancel
end

# We spawn several clients to connect to the server.
REPEATS.times do |i|
	reactor.async do
		Async.logger.info('client') {"Connecting client #{i}"}
		
		Async::IO::Socket.connect(SERVER_ADDRESS) do |client|
			Async.logger.info('client') {"Reading data on client #{i}"}
			
			message = client.read(1024)
			
			Async.logger.info('client') {"Got response #{message.inspect}"}
		end
	end
end

reactor.run
