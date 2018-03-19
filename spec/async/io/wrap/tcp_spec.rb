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

require 'net/http'

require 'async/io/tcp_socket'

RSpec.describe Async::IO::TCPSocket do
	# There are different ways to achieve this. This is really just a proof of concept.
	let(:http) {Net::HTTP.dup.include(Async::IO)}
	
	describe "inside reactor" do
		include_context Async::RSpec::Reactor
		
		it "should fetch page" do
			expect(Async::IO::TCPSocket).to receive(:open).and_call_original
			
			expect do
				http.get_response('www.google.com', '/')
			end.to_not raise_error
		end
	end
	
	describe "outside reactor" do
		it "should fetch page" do
			expect do
				Net::HTTP.get_response('www.google.com', '/')
			end.to_not raise_error
		end
	end
end
