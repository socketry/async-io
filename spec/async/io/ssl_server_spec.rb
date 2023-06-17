# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2019, by Benoit Daloze.

require 'async/io/ssl_socket'
require 'async/io/ssl_endpoint'

require 'async/rspec/ssl'
require 'async/queue'

require_relative 'generic_examples'

RSpec.describe Async::IO::SSLServer do
	include_context Async::RSpec::Reactor
	
	context 'single host' do
		include_context Async::RSpec::SSL::VerifiedContexts
		include_context Async::RSpec::SSL::ValidCertificate
		
		let(:endpoint) {Async::IO::Endpoint.tcp("127.0.0.1", 6780, reuse_port: true)}
		let(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: server_context)}
		let(:client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: client_context)}
		
		let(:data) {"What one programmer can do in one month, two programmers can do in two months."}
		
		it "can see through to address" do
			expect(server_endpoint.address).to be == endpoint.address
		end
		
		it 'can accept_each connections' do
			ready = Async::Queue.new
			
			# Accept a single incoming connection and then finish.
			server_task = reactor.async do |task|
				server_endpoint.bind do |server|
					server.listen(10)
					
					ready.enqueue(true)
					
					server.accept_each do |peer, address|
						data = peer.read(512)
						peer.write(data)
					end
				end
			end
			
			reactor.async do |task|
				ready.dequeue
				
				client_endpoint.connect do |client|
					client.write(data)
					client.close_write
					
					expect(client.read(512)).to be == data
				end
				
				server_task.stop
			end.wait
		end
	end
	
	context 'multiple hosts' do
		let(:hosts) {['test.com', 'example.com']}
		
		include_context Async::RSpec::SSL::HostCertificates
		
		let(:endpoint) {Async::IO::Endpoint.tcp("127.0.0.1", 6782, reuse_port: true)}
		let(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: server_context)}
		let(:valid_client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, hostname: 'example.com', ssl_context: client_context)}
		let(:invalid_client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, hostname: 'fleeb.com', ssl_context: client_context)}
		
		let(:data) {"What one programmer can do in one month, two programmers can do in two months."}
		
		before do
			certificates
		end
		
		it 'can select correct host' do
			ready = Async::Queue.new
			
			# Accept a single incoming connection and then finish.
			server_task = reactor.async do |task|
				server_endpoint.bind do |server|
					server.listen(10)
					
					ready.enqueue(true)
					
					server.accept_each do |peer, address|
						expect(peer.hostname).to be == 'example.com'
						
						data = peer.read(512)
						peer.write(data)
					end
				end
			end
			
			reactor.async do
				ready.dequeue
				
				valid_client_endpoint.connect do |client|
					client.write(data)
					client.close_write
					
					expect(client.read(512)).to be == data
				end
				
				server_task.stop
			end.wait
		end
		
		it 'it fails with invalid host' do
			ready = Async::Queue.new
			
			# Accept a single incoming connection and then finish.
			server_task = reactor.async do |task|
				server_endpoint.bind do |server|
					server.listen(10)
					
					ready.enqueue(true)
					
					server.accept_each do |peer, address|
						peer.close
					end
				end
			end
			
			reactor.async do
				ready.dequeue
				
				expect do
					invalid_client_endpoint.connect do |client|
					end
				end.to raise_exception(OpenSSL::SSL::SSLError, /handshake failure/)
				
				server_task.stop
			end.wait
		end
	end
end
