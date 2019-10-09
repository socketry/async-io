#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require 'async'
require 'async/io/trap'
require 'async/io/host_endpoint'
require 'async/io/stream'

endpoint = Async::IO::Endpoint.tcp('localhost', 4578)

interrupt = Async::IO::Trap.new(:INT)

Async do |top|
	interrupt.install!
	
	endpoint.bind do |server, task|
		Async.logger.info(server) {"Accepting connections on #{server.local_address.inspect}"}
		
		interrupt.async(once: true) do |subtask|
			Async.logger.info(server) {"Closing server socket..."}
			server.close
			
			interrupt.default!
			
			Async.logger.info(server) {"Waiting for connections to close..."}
			subtask.sleep(4)
			
			Async.logger.info(server) {"Stopping server task..."}
			top.stop
		end
		
		server.listen(128)
		
		server.accept_each do |peer|
			stream = Async::IO::Stream.new(peer)
			
			while chunk = stream.read_partial
				Async.logger.debug(self) {chunk.inspect}
				stream.write(chunk)
				stream.flush
			end
		end
		
		Async.logger.debug(self) {"waiting for children..."}
		task.children.each(&:wait)
		Async.logger.debug(self) {"exiting..."}
	end
end
