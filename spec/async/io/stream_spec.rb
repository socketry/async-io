# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/io/socket'
require 'async/clock'

require_relative 'generic_examples'
require_relative 'stream_context'

RSpec.describe Async::IO::Stream do
	# This constant is part of the public interface, but was renamed to `Async::IO::BLOCK_SIZE`.
	describe "::BLOCK_SIZE" do
		it "should exist and be reasonable" do
			expect(Async::IO::Stream::BLOCK_SIZE).to be_between(1024, 1024*32)
		end
	end
	
	context "socket I/O" do
		let(:sockets) do
			@sockets = Async::IO::Socket.pair(Socket::AF_UNIX, Socket::SOCK_STREAM)
		end
		
		after do
			@sockets&.each(&:close)
		end
		
		let(:io) {sockets.first}
		subject {described_class.new(sockets.last)}
		
		it_should_behave_like Async::IO
		
		describe '#close_read' do
			subject {described_class.new(sockets.last)}
			
			it "can close the reading end of the stream" do
				expect(subject.io).to receive(:close_read).and_call_original
				
				subject.close_read
				
				# Ruby <= 2.4 raises an exception even with exception: false
				# expect(stream.read).to be_nil
			end
			
			it "can close the writing end of the stream" do
				expect(subject.io).to receive(:close_write).and_call_original
				
				subject.write("Oh yes!")
				subject.close_write
				
				expect do
					subject.write("Oh no!")
					subject.flush
				end.to raise_error(IOError, /not opened for writing/)
			end
		end
		
		describe '#read_exactly' do
			it "can read several bytes" do
				io.write("hello\nworld\n")
				
				expect(subject.read_exactly(4)).to be == 'hell'
			end
			
			it "can raise exception if io is eof" do
				io.close
				
				expect do
					subject.read_exactly(4)
				end.to raise_error(EOFError)
			end
		end
	end
	
	context "performance (BLOCK_SIZE: #{Async::IO::BLOCK_SIZE} MAXIMUM_READ_SIZE: #{Async::IO::MAXIMUM_READ_SIZE})" do
		include_context Async::RSpec::Reactor
		
		let!(:stream) {described_class.open("/dev/zero")}
		after {stream.close}
		
		it "can read data quickly" do |example|
			data = nil
			
			duration = Async::Clock.measure do
				data = stream.read(1024**3)
			end
			
			size = data.bytesize / 1024**2
			rate = size / duration
			
			example.reporter.message "Read #{size.round(2)}MB of data at #{rate.round(2)}MB/s."
			
			expect(rate).to be > 128
		end
	end
	
	context "buffered I/O" do
		include_context Async::IO::Stream
		include_context Async::RSpec::Memory
		include_context Async::RSpec::Reactor
		
		describe '#read' do
			it "should read everything" do
				io.write "Hello World"
				io.seek(0)
				
				expect(subject.io).to receive(:read_nonblock).and_call_original.twice
				
				expect(subject.read).to be == "Hello World"
				expect(subject).to be_eof
			end
		
			it "should read only the amount requested" do
				io.write "Hello World"
				io.seek(0)
				
				expect(subject.io).to receive(:read_nonblock).and_call_original.twice
				
				expect(subject.read_partial(4)).to be == "Hell"
				expect(subject).to_not be_eof
				
				expect(subject.read_partial(20)).to be == "o World"
				expect(subject).to be_eof
			end
		
			context "with large content" do
				it "allocates expected amount of bytes" do
					io.write("." * 16*1024)
					io.seek(0)
					
					buffer = nil
					
					expect do
						# The read buffer is already allocated, and it will be resized to fit the incoming data. It will be swapped with an empty buffer.
						buffer = subject.read(16*1024)
					end.to limit_allocations.of(String, count: 1, size: 0)
					
					expect(buffer.size).to be == 16*1024
				end
			end
		end
		
		describe '#read_until' do
			it "can read a line" do
				io.write("hello\nworld\n")
				io.seek(0)
				
				expect(subject.read_until("\n")).to be == 'hello'
				expect(subject.read_until("\n")).to be == 'world'
				expect(subject.read_until("\n")).to be_nil
			end
		
			context "with 1-byte block size" do
				subject! {Async::IO::Stream.new(buffer, block_size: 1)}
				
				it "can read a line with a multi-byte pattern" do
					io.write("hello\r\nworld\r\n")
					io.seek(0)
					
					expect(subject.read_until("\r\n")).to be == 'hello'
					expect(subject.read_until("\r\n")).to be == 'world'
					expect(subject.read_until("\r\n")).to be_nil
				end
			end
			
			context "with large content" do
				it "allocates expected amount of bytes" do
					subject
					
					expect do
						subject.read_until("b")
					end.to limit_allocations.of(String, size: 0, count: 1)
				end
			end
		end
		
		describe '#flush' do
			it "should not call write if write buffer is empty" do
				expect(subject.io).to_not receive(:write)
				
				subject.flush
			end
		
			it "should flush underlying data when it exceeds block size" do
				expect(subject.io).to receive(:write).and_call_original.once
				
				subject.block_size.times do
					subject.write("!")
				end
			end
		end
		
		describe '#read_partial' do
			before(:each) do
				io.write("Hello World!" * 1024)
				io.seek(0)
			end
			
			it "should avoid calling read" do
				expect(subject.io).to receive(:read_nonblock).and_call_original.once
				
				expect(subject.read_partial(12)).to be == "Hello World!"
			end
			
			context "with large content" do
				it "allocates only the amount required" do
					expect do
						subject.read(4*1024)
					end.to limit_allocations.of(String, count: 2, size: 4*1024+1)
				end
				
				it "allocates exact number of bytes being read" do
					expect do
						subject.read_partial(16*1024)
					end.to limit_allocations.of(String, count: 1, size: 0)
				end
				
				it "allocates expected amount of bytes" do
					buffer = nil
					
					expect do
						buffer = subject.read_partial
					end.to limit_allocations.of(String, count: 1)
					
					expect(buffer.size).to be == subject.block_size
				end
			end
		end
		
		describe '#write' do
			it "should read one line" do
				expect(subject.io).to receive(:write).and_call_original.once
				
				subject.write "Hello World\n"
				subject.flush
				
				io.seek(0)
				expect(subject.read).to be == "Hello World\n"
			end
		end
		
		describe '#eof' do
			it "should terminate subject" do
				expect do
					subject.eof!
				end.to raise_exception(EOFError)
				
				expect(subject).to be_eof
			end
		end
		
		describe '#close' do
			it 'can be closed even if underlying io is closed' do
				io.close
				
				expect(subject.io).to be_closed
				
				# Put some data in the write buffer
				subject.write "."
				
				expect do
					subject.close
				end.to_not raise_exception
			end
		end
	end
end
