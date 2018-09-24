# Copyright, 2018, by Thibaut Girka
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

require 'http'
require 'openssl'

require 'async/io/tcp_socket'
require 'async/io/ssl_socket'

# There are different ways to achieve this. This is really just a proof of concept.
module Wrap
	class TCPSocket
		def self.new(*args)
			if Async::Task.current?
				Async::IO::TCPSocket.new(*args)
			else
				::TCPSocket.new(*args)
			end
		end
		
		def self.open(*args)
			self.new(*args)
		end
	end
	
	class SSLSocket
		def self.new(*args)
			if Async::Task.current?
				# wrap instead of new
				Async::IO::SSLSocket.wrap(*args)
			else
				OpenSSL::SSL::SSLSocket.new(*args)
			end
		end
	end
end

RSpec.describe Async::IO::TCPSocket do
	describe "inside reactor" do
		include_context Async::RSpec::Reactor
		
		it "should fetch page" do
			expect(Async::IO::TCPSocket).to receive(:new).and_call_original
			
			expect do
				HTTP.get('https://www.google.com', { socket_class: Wrap::TCPSocket, ssl_socket_class: Wrap::SSLSocket })
			end.to_not raise_error
		end
		
		it "should fetch page when used as a drop-in replacement" do
			expect(Async::IO::TCPSocket).to receive(:new).and_call_original
				HTTP.get('https://www.google.com', { socket_class: Async::IO::TCPSocket, ssl_socket_class: Async::IO::SSLSocket })
			expect do
			end.to_not raise_error
		end
	end
	
	describe "outside reactor" do
		it "should fetch page" do
			expect do
				HTTP.get('https://www.google.com', { socket_class: Wrap::TCPSocket, ssl_socket_class: Wrap::SSLSocket })
			end.to_not raise_error
		end
	end
end
