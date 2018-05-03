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

require 'async/io/socket'

require_relative 'generic_examples'

RSpec.describe Async::IO::BasicSocket do
	it_should_behave_like Async::IO::Generic
end

RSpec.describe Async::IO::Socket do
	include_context Async::RSpec::Reactor
	
	it_should_behave_like Async::IO::Generic
	
	describe '#connect' do
		let(:address) {Async::IO::Address.tcp('127.0.0.1', 12345)}
		
		it "should fail to connect if no listening server" do
			expect do
				Async::IO::Socket.connect(address)
			end.to raise_error(Errno::ECONNREFUSED)
		end
	end
	
	describe '#bind' do
		let(:address) {Async::IO::Address.tcp('127.0.0.1', 1)}
		
		it "should fail to bind to port < 1024" do
			expect do
				Async::IO::Socket.bind(address)
			end.to raise_error(Errno::EACCES)
		end
	end
	
	describe '.pair' do
		subject{described_class.pair(:UNIX, :STREAM, 0)}
		
		it "should be able to send and recv" do
			s1, s2 = *subject
			
			s1.send "Hello World", 0
			s1.close
			
			expect(s2.recv(32)).to be == "Hello World"
			s2.close
		end
		
		it "should be connected" do
			s1, s2 = *subject
			
			expect(s1).to be_connected
			
			s1.close
			
			expect(s2).to_not be_connected
			
			s2.close
		end
	end
end

RSpec.describe Async::IO::IPSocket do
	it_should_behave_like Async::IO::Generic, [:inspect]
end
