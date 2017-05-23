#!/usr/bin/env ruby

require 'async'
require 'async/logger'
require_relative '../lib/async/io/socket'

reactor = Async::Reactor.new
Async.logger.level = Logger::INFO

server_address = Addrinfo.tcp('localhost', 6777)

SERVER_ADDRESS = Addrinfo.tcp('0.0.0.0', 9000)

def echo_server
	Async::Reactor.run do |task|
		# This is a synchronous block within the current task:
		Async::IO::Socket.accept(SERVER_ADDRESS, backlog: 10) do |client|
			
			# This is an asynchronous block within the current reactor:
			task.reactor.async do
				data = client.read(512)
				
				task.sleep(rand)
				
				client.write(data)
			end
		end
	end
end

def echo_client(data)
	Async::Reactor.run do |task|
		Async::IO::Socket.connect(SERVER_ADDRESS) do |peer|
			peer.write(data)
			
			message = peer.read(512)
			Async.logger.info('client') {"Got response #{message.inspect}"}
		end
	end
end

Async::Reactor.run do
	server = echo_server
	
	5.times.collect do |i|
		echo_client("Hello World #{i}")
	end.each(&:wait)
	
	server.stop
end
