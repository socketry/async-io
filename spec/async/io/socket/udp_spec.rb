# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require 'async/io/udp_socket'

RSpec.describe Async::IO::Socket do
	include_context Async::RSpec::Reactor
	
	# Shared port for localhost network tests.
	let!(:server_address) {Async::IO::Address.udp("127.0.0.1", 6778)}
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	let!(:server_task) do
		reactor.async do
			Async::IO::Socket.bind(server_address) do |server|
				packet, address = server.recvfrom(512)
				
				server.send(packet, 0, address)
			end
		end
	end
	
	describe 'basic udp server' do
		it "should echo data back to peer" do
			Async::IO::Socket.connect(server_address) do |client|
				client.send(data)
				response = client.recv(512)
				
				expect(response).to be == data
			end
		end
		
		it "should use unconnected socket" do
			Async::IO::UDPSocket.wrap(server_address.afamily) do |client|
				client.send(data, 0, server_address)
				response, address = client.recvfrom(512)
				
				expect(response).to be == data
			end
		end
	end
end
