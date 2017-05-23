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

RSpec.describe Async::Reactor do
	include_context Async::RSpec::Leaks
	
	let(:path) {File.join(__dir__, "unix-socket")}
	let(:data) {"The quick brown fox jumped over the lazy dog."}
	
	before(:each) do
		FileUtils.rm_f path
	end
	
	describe 'basic unix socket' do
		it "should echo data back to peer" do
			subject.async do
				Async::IO::UNIXServer.wrap(path) do |server|
					server.accept.with do |peer|
						peer.send(peer.recv(512))
					end
				end
			end
			
			subject.async do
				Async::IO::UNIXSocket.wrap(path) do |client|
					client.send(data)
					response = client.recv(512)
				
					expect(response).to be == data
				end
			end
			
			subject.run
		end
	end
end
