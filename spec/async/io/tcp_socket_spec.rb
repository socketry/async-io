# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, reactor to the following conditions:
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

require 'async/io/tcp_socket'

require_relative 'generic_examples'

RSpec.describe Async::IO::TCPSocket, timeout: 1 do
	include_context Async::RSpec::Reactor
	
	it_should_behave_like Async::IO::Generic
	
	# Shared port for localhost network tests.
	let(:server_address) {Async::IO::Address.tcp("localhost", 6788)}
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	describe Async::IO::TCPServer do
		it_should_behave_like Async::IO::Generic
	end
	
	describe Async::IO::TCPServer do
		let!(:server_task) do
			reactor.async do |task|
				server = Async::IO::TCPServer.new("localhost", 6788)
				
				peer, address = server.accept
				
				data = peer.gets
				peer.puts(data)
				peer.flush
				
				peer.close
				server.close
			end
		end
		
		let(:client) {Async::IO::TCPSocket.new("localhost", 6788)}
		
		it "can read into output buffer" do
			client.puts("Hello World")
			client.flush
			
			buffer = String.new
			# 20 is bigger than echo response...
			data = client.read(20, buffer)
			
			expect(buffer).to_not be_empty
			expect(buffer).to be == data
			
			client.close
			server_task.wait
		end
		
		it "should start server and send data" do
			# Accept a single incoming connection and then finish.
			client.puts(data)
			client.flush
			
			expect(client.gets).to be == data
			
			client.close
			server_task.wait
		end
	end
end
