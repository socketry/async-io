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

require 'async/io/ssl_socket'

require 'async/rspec/ssl'

RSpec.describe Async::Reactor do
	include_context Async::RSpec::Leaks
	include_context Async::RSpec::SSL::VerifiedContexts
	
	# Shared port for localhost network tests.
	let(:endpoint) {Async::IO::Endpoint.tcp("127.0.0.1", 6779, reuse_port: true)}
	let(:server_endpoint) {Async::IO::SecureEndpoint.new(endpoint, ssl_context: server_context)}
	let(:client_endpoint) {Async::IO::SecureEndpoint.new(endpoint, ssl_context: client_context)}
	
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	around(:each) do |example|
		# Accept a single incoming connection and then finish.
		subject.async do |task|
			server_endpoint.bind do |server|
				server.listen(10)
				
				begin
					server.accept do |peer, address|
						data = peer.read(512)
						peer.write(data)
					# ensure # TODO Ruby 2.5+
						peer.close
					end
				rescue OpenSSL::SSL::SSLError
					# ignore.
				end
				
			# ensure # TODO Ruby 2.5+
				server.close
			end
		end
		
		result = example.run
		
		if result.is_a? Exception
			result 
		else
			subject.run
		end
	end
	
	describe "#connect" do
		context "with a trusted certificate" do
			include_context Async::RSpec::SSL::ValidCertificate
			
			it "should start server and send data" do
				subject.async do
					client_endpoint.connect do |client|
						client.write(data)
						expect(client.read(512)).to be == data
					# ensure # TODO Ruby 2.5+
						client.close
					end
				end
			end
		end

		context "with an untrusted certificate" do
			include_context Async::RSpec::SSL::InvalidCertificate
			
			it "should fail to connect" do
				subject.async do
					expect do
						client_endpoint.connect {|peer| peer.close}
					end.to raise_error(OpenSSL::SSL::SSLError)
				end
			end
		end
	end
end
