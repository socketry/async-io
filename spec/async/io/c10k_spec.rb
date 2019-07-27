# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'async/io'
require 'benchmark'
require 'open3'

# require 'ruby-prof'

RSpec.describe "echo client/server", if: Process.respond_to?(:fork) do
	# macOS has a rediculously hard time to do this.
	# sudo sysctl -w net.inet.ip.portrange.first=10000
	# sudo sysctl -w net.inet.ip.portrange.hifirst=10000
	# Probably due to the use of select.
	
	let(:repeats) do
		if limit = Async::IO.file_descriptor_limit
			if limit > 1024*10
				10_000
			else
				[1, limit - 100].max
			end
		else
			10_000
		end
	end
	
	let(:server_address) {Async::IO::Address.tcp('0.0.0.0', 10101)}
	
	def echo_server(server_address)
		Async do |task|
			connections = []
			
			Async::IO::Socket.bind(server_address) do |server|
				server.listen(Socket::SOMAXCONN)
				
				while connections.size < repeats
					peer, address = server.accept
					connections << peer
				end
			end.wait
			
			puts "Releasing #{connections.size} connections..."
			
			while connection = connections.pop
				connection.write(".")
				connection.close
			end
		end
	end
	
	def echo_client(server_address, data, responses)
		Async do |task|
			begin
				Async::IO::Socket.connect(server_address) do |peer|
					responses << peer.read(1)
				end
			rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EADDRINUSE
				puts "#{data}: #{$!}..."
				# If the connection was refused, it means the server probably can't accept connections any faster than it currently is, so we simply retry.
				retry
			end
		end
	end
	
	def fork_server
		pid = fork do
			# profile = RubyProf::Profile.new(merge_fibers: true)
			# profile.start
			
			echo_server(server_address)
		# ensure
		# 	result = profile.stop
		# 	printer = RubyProf::FlatPrinter.new(result)
		# 	printer.print(STDOUT)
		end

		yield
	ensure
		Process.kill(:KILL, pid)
		Process.wait(pid)
	end
	
	around(:each) do |example|
		duration = Benchmark.realtime do
			example.run
		end
		
		example.reporter.message "Handled #{repeats} connections in #{duration.round(2)}s: #{(repeats/duration).round(2)}req/s"
	end
	
	it "should wait until all clients are connected" do
		fork_server do
			# profile = RubyProf::Profile.new(merge_fibers: true)
			# profile.start
			
			Async do |task|
				responses = []
				
				tasks = repeats.times.collect do |i|
					# puts "Starting client #{i} on #{task}..." if (i % 1000) == 0
					
					echo_client(server_address, "Hello World #{i}", responses)
				end
				
				# task.reactor.print_hierarchy
				
				tasks.each(&:wait)
				
				expect(responses.size).to be repeats
			end
			
		# ensure
		# 	result = profile.stop
		# 	printer = RubyProf::FlatPrinter.new(result)
		# 	printer.print(STDOUT)
		end
	end
end
