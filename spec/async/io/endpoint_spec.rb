# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require 'async/io/endpoint'

require 'async/io/tcp_socket'
require 'async/io/socket_endpoint'
require 'async/io/ssl_endpoint'

RSpec.describe Async::IO::Endpoint do
	include_context Async::RSpec::Reactor
	
	describe Async::IO::Endpoint.ssl('0.0.0.0', 5234, hostname: "lolcathost") do
		it "should have hostname" do
			expect(subject.hostname).to be == "lolcathost"
		end
		
		it "shouldn't have a timeout duration" do
			expect(subject.timeout).to be_nil
		end
	end
	
	describe Async::IO::Endpoint.tcp('0.0.0.0', 5234, reuse_port: true, timeout: 10) do
		it "should be a tcp binding" do
			subject.bind do |server|
				expect(server.local_address.socktype).to be == ::Socket::SOCK_STREAM
			end
		end
		
		it "should have a timeout duration" do
			expect(subject.timeout).to be 10
		end
		
		it "should print nicely" do
			expect(subject.to_s).to include('0.0.0.0', '5234')
		end
		
		it "has options" do
			expect(subject.options[:reuse_port]).to be true
		end
		
		it "has hostname" do
			expect(subject.hostname).to be == '0.0.0.0'
		end
		
		it "has local address" do
			address = Async::IO::Address.tcp('127.0.0.1', 8080)
			expect(subject.with(local_address: address).local_address).to be == address
		end
		
		let(:message) {"Hello World!"}
		
		it "can connect to bound server" do
			server_task = reactor.async do
				subject.accept do |io|
					expect(io.timeout).to be == 10
					io.write message
					io.close
				end
			end
			
			io = subject.connect
			expect(io.timeout).to be == 10
			expect(io.read(message.bytesize)).to be == message
			io.close
			
			server_task.stop
		end
	end
	
	describe Async::IO::Endpoint.tcp('0.0.0.0', 0) do
		it "should be a tcp binding" do
			subject.bind do |server|
				expect(server.local_address.ip_port).to be > 10000
			end
		end
	end
	
	describe Async::IO::SocketEndpoint.new(TCPServer.new('0.0.0.0', 1234)) do
		it "should bind to given socket" do
			subject.bind do |server|
				expect(server).to be == subject.socket
			end
		end
	end
end
