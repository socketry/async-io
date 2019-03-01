#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../../lib", __dir__)

require 'async/reactor'
require 'async/io/host_endpoint'

require 'async/container'
require 'async/container/forked'

endpoint = Async::IO::Endpoint.parse(ARGV.pop || "tcp://localhost:7234")

CONNECTIONS = 1_000_000

CONCURRENCY = Async::Container.hardware_concurrency
TASKS = 16
REPEATS = (CONNECTIONS.to_f / (TASKS * CONCURRENCY)).ceil

puts "Starting #{CONCURRENCY} processes, running #{TASKS} tasks, making #{REPEATS} connections."
puts "Total number of connections: #{CONCURRENCY * TASKS * REPEATS}!"

begin
	container = Async::Container::Forked.new
	
	container.run(count: CONCURRENCY) do
		Async do |task|
			connections = []
			
			TASKS.times do
				task.async do
					REPEATS.times do
						$stdout.write "."
						connections << endpoint.connect
					end
				end
			end
		end
	end
	
	container.wait
ensure
	container.stop if container
end
