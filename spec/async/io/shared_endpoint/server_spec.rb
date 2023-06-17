# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2021, by Olle Jonsson.

require 'async/io/ssl_socket'
require 'async/rspec/ssl'

require 'async/io/host_endpoint'
require 'async/io/shared_endpoint'

require 'async/container'

RSpec.shared_examples_for Async::IO::SharedEndpoint do |container_class|
	include_context Async::RSpec::SSL::VerifiedContexts
	include_context Async::RSpec::SSL::ValidCertificate
	
	let!(:endpoint) {Async::IO::Endpoint.tcp("127.0.0.1", 6781, reuse_port: true)}
	let!(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: server_context)}
	let!(:client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: client_context)}
	
	let!(:bound_endpoint) do
		Async do
			Async::IO::SharedEndpoint.bound(server_endpoint)
		end.wait
	end
	
	let(:container) {container_class.new}
	
	it "can use bound endpoint in container" do
		container.async do
			bound_endpoint.accept do |peer|
				peer.write "Hello World"
				peer.close
			end
		end
		
		Async do
			client_endpoint.connect do |peer|
				expect(peer.read(11)).to eq "Hello World"
			end
		end
		
		container.stop
		bound_endpoint.close
	end
end

RSpec.describe Async::Container::Forked, if: Process.respond_to?(:fork) do
	it_behaves_like Async::IO::SharedEndpoint, described_class
end

RSpec.describe Async::Container::Threaded, if: (RUBY_PLATFORM !~ /darwin/ && RUBY_ENGINE != "jruby") do
	it_behaves_like Async::IO::SharedEndpoint, described_class
end
