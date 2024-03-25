# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'async/io/host_endpoint'
require 'async/io/shared_endpoint'

RSpec.describe Async::IO::SharedEndpoint do
	include_context Async::RSpec::Reactor
	
	describe '#bound' do
		let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 5123, timeout: 10)}
		
		it "can bind to shared endpoint" do
			bound_endpoint = described_class.bound(endpoint)
			expect(bound_endpoint.wrappers).to_not be_empty
			
			wrapper = bound_endpoint.wrappers.first
			expect(wrapper).to be_a Async::IO::Socket
			expect(wrapper.timeout).to be == endpoint.timeout
			expect(wrapper).to_not be_close_on_exec
			
			bound_endpoint.close
		end
		
		it "can specify close_on_exec" do
			bound_endpoint = described_class.bound(endpoint, close_on_exec: true)
			expect(bound_endpoint.wrappers).to_not be_empty
			
			wrapper = bound_endpoint.wrappers.first
			expect(wrapper).to be_close_on_exec
			
			bound_endpoint.close
		end
		
		it "can close a bound endpoint to terminate accept loop" do
			bound_endpoint = described_class.bound(endpoint)
			expect(bound_endpoint.wrappers).to_not be_empty
			
			server_task = Async do
				bound_endpoint.accept do |io|
					io.close
				end
			end
			
			connect = proc do
				endpoint.connect do |io|
					io.write "Hello World"
					io.close
				end
			end
			
			connect.call
			
			wrapper = bound_endpoint.wrappers.first
			expect(wrapper).to be_a Async::IO::Socket
			
			bound_endpoint.close
			expect(wrapper).to be_closed
			
			expect do
				begin
					# Either ECONNRESET or ECONNREFUSED can be raised here.
					connect.call
				rescue Errno::ECONNRESET
					raise Errno::ECONNREFUSED
				end
			end.to raise_error(Errno::ECONNREFUSED)
		end
	end
	
	describe '#connected' do
		let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 5124, timeout: 10)}
		
		it "can connect to shared endpoint" do
			server_task = reactor.async do
				endpoint.accept do |io|
					io.close
				end
			end
			
			connected_endpoint = described_class.connected(endpoint)
			expect(connected_endpoint.wrappers).to_not be_empty
			
			wrapper = connected_endpoint.wrappers.first
			expect(wrapper).to be_a Async::IO::Socket
			expect(wrapper.timeout).to be == endpoint.timeout
			expect(wrapper).to_not be_close_on_exec
			
			connected_endpoint.close
			server_task.stop
		end
	end
end
