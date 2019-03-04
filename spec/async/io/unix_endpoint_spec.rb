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

require 'async/io/unix_endpoint'

RSpec.describe Async::IO::UNIXEndpoint do
	include_context Async::RSpec::Reactor
	
	let(:data) {"The quick brown fox jumped over the lazy dog."} 
	let(:path) {File.join(__dir__, "unix-socket")}
	subject {described_class.unix(path)}
	
	before(:each) do
		FileUtils.rm_f path
	end
	
	after do
		FileUtils.rm_f path
	end
	
	it "should echo data back to peer" do
		server_task = reactor.async do
			subject.accept do |peer|
				peer.send(peer.recv(512))
			end
		end
		
		reactor.async do
			subject.connect do |client|
				client.send(data)
				
				response = client.recv(512)
				
				expect(response).to be == data
			end
		end.wait
		
		server_task.stop
	end
	
	it "should fails to bind if there is an existing binding" do
		condition = Async::Condition.new
		
		reactor.async do
			condition.wait
			
			expect do
				subject.bind
			end.to raise_error(Errno::EADDRINUSE)
		end
		
		server_task = reactor.async do
			subject.bind do |server|
				server.listen(1)
				condition.signal
			end
		end
		
		server_task.stop
	end
end
