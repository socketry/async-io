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

require 'async/io/tcp_socket'

RSpec.describe Async::IO::Socket do
	include_context Async::RSpec::Reactor
	
	# Shared port for localhost network tests.
	let(:server_address) {Async::IO::Address.tcp("127.0.0.1", 6788)}
	let(:local_address) {Async::IO::Address.tcp("127.0.0.1", 0)}
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	let!(:server_task) do
		# Accept a single incoming connection and then finish.
		reactor.async do |task|
			Async::IO::Socket.bind(server_address) do |server|
				server.listen(10)
				
				server.accept do |peer, address|
					data = peer.read(512)
					peer.write(data)
				end
			end
		end
	end
	
	describe 'basic tcp server' do
		it "should start server and send data" do
			reactor.async do
				Async::IO::Socket.connect(server_address) do |client|
					client.write(data)
					client.close_write
					
					expect(client.read(512)).to be == data
				end
			end
		end
	end
	
	describe 'non-blocking tcp connect' do
		it "can specify local address" do
			reactor.async do |task|
				Async::IO::Socket.connect(server_address, local_address: local_address) do |client|
					client.write(data)
					client.close_write
					
					expect(client.read(512)).to be == data
				end
			end
		end
		
		it "should start server and send data" do
			reactor.async do |task|
				Async::IO::Socket.connect(server_address) do |client|
					client.write(data)
					client.close_write
					
					expect(client.read(512)).to be == data
				end
			end
		end
		
		it "can connect socket and read/write in a different task" do
			reactor.async do |task|
				socket = Async::IO::Socket.connect(server_address)
				
				expect(socket).to_not be_nil
				expect(socket).to be_kind_of Async::Wrapper
				
				reactor.async do
					socket.write(data)
					socket.close_write
					
					expect(socket.read(512)).to be == data
					
					socket.close
				end
			end
		end
	end
end
