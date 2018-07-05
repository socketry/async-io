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

RSpec.describe Async::IO::Stream do
	include_context Async::RSpec::Memory
	
	let(:io) {StringIO.new}
	let(:stream) {Async::IO::Stream.new(io)}
	
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
			let!(:io) { StringIO.new("a" * 5*1024*1024) }
			
			it "allocates expected amount of bytes" do
				expect do
					stream.read(16*1024).clear until stream.eof?
				end.to limit_allocations(size: 100*1024)
			end
		end
	end
	
	describe '#read_until' do
		include_context Async::RSpec::Memory
		
		it "can read a line" do
			io.write("hello\nworld\n")
			io.seek(0)
			
			expect(stream.read_until("\n")).to be == 'hello'
			expect(stream.read_until("\n")).to be == 'world'
			expect(stream.read_until("\n")).to be_nil
		end
		
		it "minimises allocations" do
			io.write("hello\nworld\n")
			io.seek(0)
			
			expect do
				stream.read_until("\n")
			end.to limit_allocations(String => 3)
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
		it "should avoid calling read" do
			io.write "Hello World" * 1024
			io.seek(0)
			
			expect(io).to receive(:read).and_call_original.once
			
			expect(stream.read_partial(11)).to be == "Hello World"
		end
		
		context "with large content" do
			let!(:io) { StringIO.new("a" * 5*1024*1024) }
			
			it "allocates expected amount of bytes" do
				expect do
					stream.read_partial(16*1024).clear until stream.eof?
				end.to limit_allocations(size: 100*1024)
			end
		end
	end
	
	describe '#write' do
		it "should read one line" do
			expect(io).to receive(:write).and_call_original.once
			
			stream.write "Hello World\n"
			stream.flush
			
			expect(io.string).to be == "Hello World\n"
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
