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

require 'async/io/ssl_endpoint'

require 'async/rspec/ssl'
require_relative 'generic_examples'

RSpec.describe Async::IO::SSLSocket do
	include_context Async::RSpec::Reactor
	include_context Async::RSpec::SSL::VerifiedContexts
	
	it_should_behave_like Async::IO::Generic
	
	# Shared port for localhost network tests.
	let(:endpoint) {Async::IO::Endpoint.tcp("127.0.0.1", 6779, reuse_port: true, timeout: 10)}
	let(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: server_context, timeout: 20)}
	let(:client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: client_context, timeout: 20)}
	
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	let(:server_task) do
		# Accept a single incoming connection and then finish.
		reactor.async do |task|
			server_endpoint.bind do |server|
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
	end
	
	describe "#connect" do
		context "with a trusted certificate" do
			include_context Async::RSpec::SSL::ValidCertificate
			
			it "should start server and send data" do
				server_task
				
				reactor.async do
					client_endpoint.connect do |client|
						expect(client).to be_connected
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
				server_task
				
				reactor.async do
					expect do
						client_endpoint.connect
					end.to raise_exception(OpenSSL::SSL::SSLError)
				end
			end
		end
	end
end
