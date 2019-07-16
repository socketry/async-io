# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/io/ssl_socket'
require 'async/io/ssl_endpoint'

require 'async/rspec/ssl'
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
			# Accept a single incoming connection and then finish.
			server_task = reactor.async do |task|
				server_endpoint.bind do |server|
					server.listen(10)
					
					server.accept_each do |peer, address|
						data = peer.read(512)
						peer.write(data)
					end
				end
			end
			
			reactor.async do
				client_endpoint.connect do |client|
					client.write(data)
					client.close_write
					
					expect(client.read(512)).to be == data
				end
				
				server_task.stop
			end
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
		
		it 'can select correct host' do
			# Accept a single incoming connection and then finish.
			server_task = reactor.async do |task|
				server_endpoint.bind do |server|
					server.listen(10)
					
					server.accept_each do |peer, address|
						expect(peer.hostname).to be == 'example.com'
						
						data = peer.read(512)
						peer.write(data)
					end
				end
			end
			
			reactor.async do
				valid_client_endpoint.connect do |client|
					client.write(data)
					client.close_write
					
					expect(client.read(512)).to be == data
				end
				
				server_task.stop
			end
		end
		
		it 'it fails with invalid host' do
			# Accept a single incoming connection and then finish.
			server_task = reactor.async do |task|
				server_endpoint.bind do |server|
					server.listen(10)
					
					server.accept_each do |peer, address|
						peer.close
					end
				end
			end
			
			reactor.async do
				expect do
					invalid_client_endpoint.connect do |client|
					end
				end.to raise_exception(OpenSSL::SSL::SSLError, /handshake failure/)
				
				server_task.stop
			end
		end
	end
end
