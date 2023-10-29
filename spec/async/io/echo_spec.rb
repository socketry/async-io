# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2020, by Benoit Daloze.

require 'async/io'
require 'async/io/address'

RSpec.describe "echo client/server" do
	include_context Async::RSpec::Reactor
	
	let(:server_address) {Async::IO::Address.tcp('0.0.0.0', 9002)}
	
	def echo_server(server_address)
		server = server_address.bind
		server.listen(10)
		
		Async do
			while true
				peer, address = server.accept
				# This is an asynchronous block within the current reactor:
				data = peer.read(512)
				
				# This produces out-of-order responses.
				sleep(rand * 0.01)
				
				peer.write(data)
			end
		ensure
			server.close
		end
	end
	
	def echo_client(server_address, data, responses)
		Async do |task|
			server_address.connect do |peer|
				result = peer.write(data)
				peer.close_write
				
				message = peer.read(data.bytesize)
				
				responses << message
			end
		end
	end
	
	let(:repeats) {10}

	it "should echo several messages" do
		server = echo_server(server_address)
		responses = []
		
		tasks = repeats.times.map do |i|
			echo_client(server_address, "Hello World #{i}", responses)
		end
		
		# reactor.print_hierarchy
		
		tasks.each(&:wait)
		server.stop
		
		expect(responses.size).to be repeats
	end
end
