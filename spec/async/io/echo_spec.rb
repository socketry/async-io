# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2020, by Benoit Daloze.

require 'async/io'

RSpec.describe "echo client/server" do
	include_context Async::RSpec::Reactor
	
	let(:server_address) {Async::IO::Address.tcp('0.0.0.0', 9002)}
	
	def echo_server(server_address)
		Async do |task|
			# This is a synchronous block within the current task:
			Async::IO::Socket.accept(server_address) do |client|
				# This is an asynchronous block within the current reactor:
				data = client.read(512)
				
				# This produces out-of-order responses.
				task.sleep(rand * 0.01)
				
				client.write(data)
			end
		end
	end
	
	def echo_client(server_address, data, responses)
		Async do |task|
			Async::IO::Socket.connect(server_address) do |peer|
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
		
		# task.reactor.print_hierarchy
		
		tasks.each(&:wait)
		server.stop
		
		expect(responses.size).to be repeats
	end
end
