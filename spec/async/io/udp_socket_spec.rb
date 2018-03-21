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

require 'async/io/udp_socket'

require_relative 'generic_examples'

RSpec.describe Async::IO::UDPSocket do
	include_context Async::RSpec::Reactor
	
	it_should_behave_like Async::IO::Generic
	
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	it "should echo data back to peer" do
		reactor.async do
			server = Async::IO::UDPSocket.new(Socket::AF_INET)
			server.bind("127.0.0.1", 6778)
			
			packet, address = server.recvfrom(512)
			server.send(packet, 0, address[3], address[1])
			
			server.close
		end
		
		reactor.async do
			client = Async::IO::UDPSocket.new(Socket::AF_INET)
			client.connect("127.0.0.1", 6778)
			
			client.send(data, 0)
			response = client.recv(512)
			client.close
			
			expect(response).to be == data
		end
	end
end
