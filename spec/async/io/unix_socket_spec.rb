# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require 'async/io/unix_socket'

require_relative 'generic_examples'
require 'fileutils'

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
		
		Async::IO::UNIXSocket.wrap(path) do |client|
			client.send(data)
			
			response = client.recv(512)
			
			expect(response).to be == data
		end
	end
end

RSpec.describe Async::IO::UNIXServer do
	it_should_behave_like Async::IO::Generic
end
