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

require 'async/io/host_endpoint'
require 'async/io/shared_endpoint'

require 'pry'

RSpec.describe Async::IO::SharedEndpoint do
	include_context Async::RSpec::Reactor
	
	describe '#bound' do
		let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 5123, timeout: 10)}
		
		it "can bind to shared endpoint" do
			bound_endpoint = described_class.bound(endpoint)
			expect(bound_endpoint.wrappers).to_not be_empty
			
			wrapper = bound_endpoint.wrappers.first
			expect(wrapper).to be_a Async::IO::Socket
			expect(wrapper.timeout).to be == endpoint.timeout
			
			bound_endpoint.close
		end
	end
	
	describe '#connected' do
		let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 5124, timeout: 10)}
		
		it "can connect to shared endpoint" do
			server_task = reactor.async do
				endpoint.accept do |io|
					io.close
				end
			end
			
			connected_endpoint = described_class.connected(endpoint)
			expect(connected_endpoint.wrappers).to_not be_empty
			
			wrapper = connected_endpoint.wrappers.first
			expect(wrapper).to be_a Async::IO::Socket
			expect(wrapper.timeout).to be == endpoint.timeout
			
			connected_endpoint.close
			server_task.stop
		end
	end
end
