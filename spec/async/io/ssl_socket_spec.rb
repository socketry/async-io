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

RSpec.describe Async::Reactor do
	include_context Async::RSpec::Leaks
	
	let(:ssl_client_params) do
		{
			ca_file: File.expand_path(certificate_authority_key_file, __dir__)
		}
	end

	let(:ssl_server_params) do
		{
			cert: OpenSSL::X509::Certificate.new(File.read(server_cert_file)),
			key: OpenSSL::PKey::RSA.new(File.read(server_key_file))
		}
	end
	
	# Shared port for localhost network tests.
	let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 6779, reuse_port: true)}
	let(:server_endpoint) {Async::IO::SecureEndpoint.new(endpoint, ssl_params: ssl_server_params)}
	let(:client_endpoint) {Async::IO::SecureEndpoint.new(endpoint, ssl_params: ssl_client_params)}
	
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	around(:each) do |example|
		# Accept a single incoming connection and then finish.
		subject.async do |task|
			server_endpoint.bind do |server|
				server.listen(10)
				
				server.accept do |peer, address|
					data = peer.read(512)
					peer.write(data)
				end rescue nil
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
			let(:certificate_authority_key_file) {File.expand_path("ssl/trusted-ca.crt", __dir__)}
			let(:server_cert_file) {File.expand_path("ssl/trusted-cert.crt", __dir__)}
			let(:server_key_file) {File.expand_path("ssl/trusted-cert.key", __dir__)}
			
			it "should start server and send data" do
				subject.async do
					client_endpoint.connect do |client|
						client.write(data)
						expect(client.read(512)).to be == data
					end
				end
			end
		end

		context "with an untrusted certificate" do
			let(:certificate_authority_key_file) {File.expand_path("ssl/trusted-ca.crt", __dir__)}
			let(:server_cert_file) {File.expand_path("ssl/untrusted-cert.crt", __dir__)}
			let(:server_key_file) {File.expand_path("ssl/untrusted-cert.key", __dir__)}
			
			it "should fail to connect" do
				subject.async do
					expect do
						client_endpoint.connect
					end.to raise_error(OpenSSL::SSL::SSLError)
				end
			end
		end
	end
end
