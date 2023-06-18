# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'async/io/ssl_endpoint'
require 'async/queue'
require 'async/rspec/ssl'

require_relative 'generic_examples'

RSpec.describe Async::IO::SSLSocket do
	it_should_behave_like Async::IO::Generic
	
	describe "#connect" do
		include_context Async::RSpec::Reactor
		include_context Async::RSpec::SSL::VerifiedContexts
		
		# Shared port for localhost network tests.
		let!(:endpoint) {Async::IO::Endpoint.tcp("127.0.0.1", 6779, reuse_port: true, timeout: 10)}
		let!(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: server_context, timeout: 20)}
		let!(:client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: client_context, timeout: 20)}
		
		let(:data) {"The quick brown fox jumped over the lazy dog."}
		
		let!(:server_task) do
			ready = Async::Queue.new
			
			# Accept a single incoming connection and then finish.
			reactor.async do |task|
				server_endpoint.bind do |server|
					ready.enqueue(server)
					server.listen(10)
					
					begin
						server.accept do |peer, address|
							expect(peer.timeout).to be == 10
							
							data = peer.read(512)
							peer.write(data)
						end
					rescue OpenSSL::SSL::SSLError
						# ignore.
					end
				end
			end
			
			ready.dequeue
		end
		
		context "with a trusted certificate" do
			include_context Async::RSpec::SSL::ValidCertificate
			
			it "should start server and send data" do
				reactor.async do
					client_endpoint.connect do |client|
						# expect(client).to be_connected
						expect(client.timeout).to be == 10
						
						client.write(data)
						client.close_write
						
						expect(client.read(512)).to be == data
					end
				end
			end
		end
		
		context "with an untrusted certificate" do
			include_context Async::RSpec::SSL::InvalidCertificate
			
			it "should fail to connect" do
				reactor.async do
					expect do
						client_endpoint.connect
					end.to raise_exception(OpenSSL::SSL::SSLError)
				end.wait
			end
		end
	end
end
