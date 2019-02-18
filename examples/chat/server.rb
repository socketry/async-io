#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../../lib", __dir__)

require 'set'

require 'async'
require 'async/io/host_endpoint'
require 'async/io/protocol/line'

class User < Async::IO::Protocol::Line
	attr_accessor :name
	
	def login!
		self.write_lines "Tell me your name, traveller:"
		self.name = self.read_line
	end
	
	def to_s
		@name || "unknown"
	end
end

class Server
	def initialize
		@users = Set.new
	end
	
	def broadcast(*message)
		puts *message
		
		@users.each do |user|
			begin
				user.write_lines(*message)
			rescue EOFError
				# In theory, it's possible this will fail if the remote end has disconnected. Each user has it's own task running `#connected`, and eventually `user.read_line` will fail. When it does, the disconnection logic will be invoked. A better way to do this would be to have a message queue, but for the sake of keeping this example simple, this is by far the better option.
			end
		end
	end
	
	def connected(user)
		user.login!
		
		broadcast("#{user} has joined")
		
		user.write_lines("currently connected: #{@users.map(&:to_s).join(', ')}")
		
		while message = user.read_line
			broadcast("#{user.name}: #{message}")
		end
	rescue EOFError
		# It's okay, client has disconnected.
	ensure
		disconnected(user)
	end
	
	def disconnected(user, reason = "quit")
		@users.delete(user)
		
		broadcast("#{user} has disconnected: #{reason}")
	end
	
	def run(endpoint)
		Async do |task|
			endpoint.accept do |peer|
				stream = Async::IO::Stream.new(peer)
				user = User.new(stream)
				
				@users << user
				
				connected(user)
			end
		end
	end
end

Async.logger.level = Logger::INFO
Async.logger.info("Starting server...")
server = Server.new

endpoint = Async::IO::Endpoint.parse(ARGV.pop || "tcp://localhost:7138")
server.run(endpoint)
