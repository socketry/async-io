# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

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
		end.wait
	end
end
