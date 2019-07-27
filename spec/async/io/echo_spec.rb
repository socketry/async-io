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

RSpec.describe "echo client/server" do
	include_context Async::RSpec::Reactor
	
	let(:server_address) {Async::IO::Address.tcp('0.0.0.0', 9002)}
	
	def echo_server(server_address)
		Async do |task|
			# This is a synchronous block within the current task:
			Async::IO::Socket.accept(server_address) do |client|
				# This is an asynchronous block within the current reactor:
				data = client.read(512)
				
				# This produces out-of-order responses.
				task.sleep(rand * 0.01)
				
				client.write(data)
			end
		end
	end
	
	def echo_client(server_address, data, responses)
		Async do |task|
			Async::IO::Socket.connect(server_address) do |peer|
				result = peer.write(data)
				peer.close_write
				
				message = peer.read(data.bytesize)
				
				responses << message
			end
		end
	end
	
	let(:repeats) {10}

	it "should echo several messages" do
		server = echo_server(server_address)
		responses = []
		
		tasks = repeats.times.collect do |i|
			echo_client(server_address, "Hello World #{i}", responses)
		end
		
		# task.reactor.print_hierarchy
		
		tasks.each(&:wait)
		server.stop
		
		expect(responses.size).to be repeats
	end
end
