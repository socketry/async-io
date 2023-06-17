# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require 'async/io/protocol/line'
require 'async/io/socket'

RSpec.describe Async::IO::Protocol::Line do
	include_context Async::RSpec::Reactor
	
	let(:pipe) {@pipe = Async::IO::Socket.pair(Socket::AF_UNIX, Socket::SOCK_STREAM)}
	let(:remote) {pipe.first}
	subject {described_class.new(Async::IO::Stream.new(pipe.last, deferred: true), "\n")}
	
	after(:each) {defined?(@pipe) && @pipe&.each(&:close)}
	
	context "default line ending" do
		subject {described_class.new(nil)}
		
		it "should have default eol terminator" do
			expect(subject.eol).to_not be_nil
		end
	end
	
	describe '#write_lines' do
		it "should write line" do
			subject.write_lines "Hello World"
			subject.close
			
			expect(remote.read).to be == "Hello World\n"
		end
	end
	
	describe '#read_line' do
		before(:each) do
			remote.write "Hello World\n"
			remote.close
		end
		
		it "should read one line" do
			expect(subject.read_line).to be == "Hello World"
		end
		
		it "should be binary encoding" do
			expect(subject.read_line.encoding).to be == Encoding::BINARY
		end
	end
	
	describe '#read_lines' do
		before(:each) do
			remote.write "Hello\nWorld\n"
			remote.close
		end
		
		it "should read multiple lines" do
			expect(subject.read_lines).to be == ["Hello", "World"]
		end
		
		it "should be binary encoding" do
			expect(subject.read_lines.first.encoding).to be == Encoding::BINARY
		end
	end
end
