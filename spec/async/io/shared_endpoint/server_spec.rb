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

require 'async/io/host_endpoint'
require 'async/io/shared_endpoint'

require 'async/container/forked'
require 'async/container/threaded'

RSpec.shared_examples_for Async::IO::SharedEndpoint do |container_class|
	include_context Async::RSpec::SSL::VerifiedContexts
	include_context Async::RSpec::SSL::ValidCertificate
	
	let(:endpoint) {Async::IO::Endpoint.tcp("127.0.0.1", 6781, reuse_port: true)}
	let(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: server_context)}
	let(:client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: client_context)}
	
	let!(:bound_endpoint) do
		Async do
			Async::IO::SharedEndpoint.bound(server_endpoint)
		end.wait
	end
	
	let(:container) {container_class.new}
	
	it "can use bound endpoint in container" do
		container.run(count: 1) do
			bound_endpoint.accept do |peer|
				peer.write "Hello World"
				peer.close
			end
		end
		
		container.wait do
			Async do
				client_endpoint.connect do |peer|
					expect(peer.read(11)).to eq "Hello World"
				end
			end
			
			container.stop(false)
		end
		
		bound_endpoint.close
	end
end

RSpec.describe Async::Container::Forked, if: Process.respond_to?(:fork) do
	it_behaves_like Async::IO::SharedEndpoint, described_class
end

RSpec.describe Async::Container::Threaded, if: RUBY_PLATFORM !~ /darwin/ do
	it_behaves_like Async::IO::SharedEndpoint, described_class
end
