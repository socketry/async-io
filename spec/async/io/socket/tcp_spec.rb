# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'async/io/tcp_socket'
require 'async/io/address'

RSpec.describe Async::IO::Socket do
	include_context Async::RSpec::Reactor
	
	# Shared port for localhost network tests.
	let(:server_address) {Async::IO::Address.tcp("127.0.0.1", 6788)}
	let(:local_address) {Async::IO::Address.tcp("127.0.0.1", 0)}
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	let!(:server_task) do
		# Accept a single incoming connection and then finish.
		Async::IO::Socket.bind(server_address) do |server|
			server.listen(10)
			
			server.accept do |peer, address|
				data = peer.read(512)
				peer.write(data)
			end
		end
	end
	
	describe 'basic tcp server' do
		it "should start server and send data" do
			server_address.connect do |client|
				client.write(data)
				client.close_write
				
				expect(client.read(512)).to be == data
			end
		end
	end
	
	describe 'non-blocking tcp connect' do
		it "can specify local address" do
			Async::IO::Socket.connect(server_address, local_address: local_address) do |client|
				client.write(data)
				client.close_write
				
				expect(client.read(512)).to be == data
			end
		end
		
		it "should start server and send data" do
			Async::IO::Socket.connect(server_address) do |client|
				client.write(data)
				client.close_write
				
				expect(client.read(512)).to be == data
			end
		end
		
		it "can connect socket and read/write in a different task" do
			socket = Async::IO::Socket.connect(server_address)
			
			expect(socket).to_not be_nil
			expect(socket).to be_kind_of Async::Wrapper
			
			reactor.async do
				socket.write(data)
				socket.close_write
				
				expect(socket.read(512)).to be == data
			end.wait
			
			socket.close
		end
	end
end
