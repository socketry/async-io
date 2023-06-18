# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require 'async/io/tcp_socket'

require_relative 'generic_examples'

RSpec.describe Async::IO::TCPSocket do
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
