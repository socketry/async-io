# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'async/io/unix_endpoint'
require 'async/io/stream'

RSpec.describe Async::IO::UNIXEndpoint do
	include_context Async::RSpec::Reactor
	
	let(:data) {"The quick brown fox jumped over the lazy dog."} 
	let(:path) {File.join(__dir__, "unix-socket")}
	subject {described_class.unix(path)}
	
	it "should echo data back to peer" do
		server_task = reactor.async do
			subject.accept do |peer|
				peer.send(peer.recv(512))
			end
		end
		
		subject.connect do |client|
			client.send(data)
			
			response = client.recv(512)
			
			expect(response).to be == data
		end
		
		server_task.stop
	end

  it "should not fail to bind if there are no existing bindings on the socket" do
    server_task1 = reactor.async do
			subject.bind
		end
		server_task1.stop

    server_task2 = reactor.async do
      expect do
				subject.bind
			end.to_not raise_error
    end
    server_task2.stop
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
	
	context "using buffered stream" do
		it "can use stream to read and write data" do
			server_task = reactor.async do |task|
				subject.accept do |peer|
					stream = Async::IO::Stream.new(peer)
					stream.write(stream.read)
					stream.close
				end
			end
			
			reactor.async do
				subject.connect do |client|
					stream = Async::IO::Stream.new(client)
					
					stream.write(data)
					stream.close_write
					
					expect(stream.read).to be == data
				end
			end.wait
			
			server_task.stop
		end
	end
end
