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

require 'async/io/stream'
require 'async/rspec/buffer'

RSpec.describe Async::IO::Stream do
	include_context Async::RSpec::Buffer
	include_context Async::RSpec::Memory
	include_context Async::RSpec::Reactor
	
	let!(:stream) {Async::IO::Stream.new(buffer)}
	let(:io) {stream.io}
	
	describe '#read' do
		it "should read everything" do
			io.write "Hello World"
			io.seek(0)
			
			expect(io).to receive(:read).and_call_original.twice
			
			expect(stream.read).to be == "Hello World"
			expect(stream).to be_eof
		end
		
		it "should read only the amount requested" do
			io.write "Hello World"
			io.seek(0)
			
			expect(io).to receive(:read).and_call_original.twice
			
			expect(stream.read(4)).to be == "Hell"
			expect(stream).to_not be_eof
			
			expect(stream.read(20)).to be == "o World"
			expect(stream).to be_eof
		end
		
		context "with large content" do
			it "allocates expected amount of bytes" do
				io.write("." * 16*1024)
				io.seek(0)
				
				buffer = nil
				
				expect do
					# The read buffer is already allocated, and it will be resized to fit the incoming data. It will be swapped with an empty buffer.
					buffer = stream.read(16*1024)
				end.to limit_allocations.of(String, count: 1, size: 0)
				
				expect(buffer.size).to be == 16*1024
				
				io.close
			end
		end
	end
	
	describe '#read_until' do
		it "can read a line" do
			io.write("hello\nworld\n")
			io.seek(0)
			
			expect(stream.read_until("\n")).to be == 'hello'
			expect(stream.read_until("\n")).to be == 'world'
			expect(stream.read_until("\n")).to be_nil
		end
		
		context "with large content" do
			it "allocates expected amount of bytes" do
				expect do
					stream.read_until("b")
				end.to limit_allocations.of(String, size: 0, count: 1)
			end
		end
	end
	
	describe '#flush' do
		it "should not call write if write buffer is empty" do
			expect(io).to_not receive(:write)
			
			stream.flush
		end
		
		it "should flush underlying data when it exceeds block size" do
			expect(io).to receive(:write).and_call_original.once
			
			stream.block_size.times do
				stream.write("!")
			end
		end
	end
	
	describe '#read_partial' do
		before(:each) do
			io.write "Hello World!" * 1024
			io.seek(0)
		end
		
		it "should avoid calling read" do
			expect(io).to receive(:read).and_call_original.once
			
			expect(stream.read_partial(12)).to be == "Hello World!"
		end
		
		context "with large content" do
			it "allocates only the amount required" do
				expect do
					stream.read(4*1024)
				end.to limit_allocations.of(String, count: 2, size: 4*1024+1)
			end
			
			it "allocates exact number of bytes being read" do
				expect do
					stream.read(16*1024)
				end.to limit_allocations.of(String, count: 1, size: 0)
			end
			
			it "allocates expected amount of bytes" do
				buffer = nil
				
				expect do
					buffer = stream.read_partial
				end.to limit_allocations.of(String, count: 1)
				
				expect(buffer.size).to be == stream.block_size
			end
		end
	end
	
	describe '#write' do
		it "should read one line" do
			expect(io).to receive(:write).and_call_original.once
			
			stream.write "Hello World\n"
			stream.flush
			
			io.seek(0)
			
			expect(stream.read).to be == "Hello World\n"
		end
	end
	
	describe '#eof' do
		it "should terminate stream" do
			expect do
				stream.eof!
			end.to raise_error(EOFError)
			
			expect(stream).to be_eof
		end
	end
	
	describe '#close' do
		it 'can be closed even if underlying io is closed' do
			io.close
			
			expect(stream.io).to be_closed
			
			# Put some data in the write buffer
			stream.write "."
			
			expect do
				stream.close
			end.to_not raise_error
		end
	end
end
