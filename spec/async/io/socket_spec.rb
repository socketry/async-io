# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2018, by Thibaut Girka.

require 'async/io/socket'
require 'async/io/address'

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
				address.connect
			end.to raise_exception(Errno::ECONNREFUSED)
		end
	end
	
	describe '#bind' do
		it "should fail to bind to port < 1024" do
			address = Async::IO::Address.tcp('127.0.0.1', 1)
			
			expect do
				Async::IO::Socket.bind(address)
			end.to raise_exception(Errno::EACCES)
		end
		
		it "can bind to port 0" do
			address = Async::IO::Address.tcp('127.0.0.1', 0)
			
			Async::IO::Socket.bind(address) do |socket|
				expect(socket.local_address.ip_port).to be > 10000
				
				expect(Async::Task.current.annotation).to include("#{socket.local_address.ip_port}")
			end
		end
	end
	
	describe '#sync' do
		it "should set TCP_NODELAY" do
			address = Async::IO::Address.tcp('127.0.0.1', 0)
			
			socket = Async::IO::Socket.wrap(::Socket::AF_INET, ::Socket::SOCK_STREAM, ::Socket::IPPROTO_TCP)
			
			socket.sync = true
			expect(socket.getsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY).bool).to be true
			
			socket.close
		end
	end
	
	describe '#timeout' do
		subject{described_class.pair(:UNIX, :STREAM, 0)}
		
		it "should timeout while waiting to receive data" do
			s1, s2 = *subject
			
			s2.timeout = 1
			
			expect{s2.recv(32)}.to raise_exception(Async::TimeoutError, "execution expired")
			
			s1.close
			s2.close
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
	
	context '.pipe' do
		let(:sockets) do
			@sockets = described_class.pair(Socket::AF_UNIX, Socket::SOCK_STREAM)
		end
		
		after do
			@sockets&.each(&:close)
		end
		
		let(:io) {sockets.first}
		subject {sockets.last}
		
		it_should_behave_like Async::IO
	end
end

RSpec.describe Async::IO::IPSocket do
	it_should_behave_like Async::IO::Generic, [:inspect]
end
