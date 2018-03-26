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

require 'async/io/unix_socket'

require_relative 'generic_examples'

RSpec.describe Async::IO::UNIXSocket do
	include_context Async::RSpec::Reactor
	
	it_should_behave_like Async::IO::Generic
	
	let(:path) {File.join(__dir__, "unix-socket")}
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	before(:each) do
		FileUtils.rm_f path
	end
	
	after do
		FileUtils.rm_f path
	end
	
	it "should echo data back to peer" do
		reactor.async do
			Async::IO::UNIXServer.wrap(path) do |server|
				server.accept do |peer|
					peer.send(peer.recv(512))
				end
			end
		end
		
		reactor.async do
			Async::IO::UNIXSocket.wrap(path) do |client|
				client.send(data)
				
				response = client.recv(512)
				
				expect(response).to be == data
			end
		end
	end
end

RSpec.describe Async::IO::UNIXServer do
	it_should_behave_like Async::IO::Generic
end
