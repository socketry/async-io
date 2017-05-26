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

RSpec.describe "echo client/server" do
	include_context Async::RSpec::Reactor
	
	let(:server_address) {Async::IO::Address.new([:tcp, '0.0.0.0', 9000])}
	
	def echo_server(server_address)
		Async::Reactor.run do |task|
			# This is a synchronous block within the current task:
			Async::IO::Socket.accept(server_address) do |client|
				# This is an asynchronous block within the current reactor:
				data = client.read(512)
				
				client.write(data)
			end
		end
	end
	
	def echo_client(server_address, data, responses)
		Async::Reactor.run do |task|
			Async::IO::Socket.connect(server_address) do |peer|
				result = peer.write(data)
				
				message = peer.read(512)
				
				responses << message
			end
		end
	end
	
	let(:repeats) {10000}
	
	around(:each) do |example|
		duration = Benchmark.realtime do
			example.run
		end
		
		example.reporter.message "Handled #{repeats} connections in #{duration}: #{repeats/duration}req/s"
	end
	
	it "should echo several messages" do
		server = echo_server(server_address)
		responses = []
		
		task = Async::Task.current
		
		tasks = repeats.times.collect do |i|
			# puts "Starting client #{i} on #{task}..."
			
			# TODO Fix this rate limiting workaround.
			task.sleep(0.000001) while task.children.count > Socket::SOMAXCONN
			
			echo_client(server_address, "Hello World #{i}", responses)
		end
		
		# task.reactor.print_hierarchy
		
		tasks.each(&:wait)
		server.stop
		
		expect(responses.count).to be repeats
	end
end
