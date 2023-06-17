#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2020, by Bruno Sutic.

$LOAD_PATH << File.expand_path("../../lib", __dir__)

require 'set'
require 'logger'

require 'async'
require 'async/reactor'
require 'async/io/host_endpoint'
require 'async/io/protocol/line'

class Server
	def initialize
		@connections = []
	end
	
	def run(endpoint)
		Async do |task|
			task.async do |subtask|
				while true
					subtask.sleep 10
					puts "Connection count: #{@connections.size}"
				end
			end
				
			
			endpoint.accept do |peer|
				stream = Async::IO::Stream.new(peer)
				
				@connections << stream
			end
		end
	end
end

Console.logger.level = Logger::INFO
Console.logger.info("Starting server...")
server = Server.new

endpoint = Async::IO::Endpoint.parse(ARGV.pop || "tcp://localhost:7234")
server.run(endpoint)
