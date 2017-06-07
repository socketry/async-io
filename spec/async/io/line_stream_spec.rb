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

RSpec.describe Async::IO::LineStream do
	let(:io) {StringIO.new}
	let(:stream) {Async::IO::LineStream.new(io, eol: "\n")}
	
	describe '#puts' do
		it "should write line" do
			stream.puts "Hello World"
			stream.flush
			
			expect(io.string).to be == "Hello World\n"
		end
	end
	
	describe '#readline' do
		before(:each) do
			io.puts "Hello World"
			io.seek(0)
		end
		
		it "should read one line" do
			expect(stream.readline).to be == "Hello World"
		end
		
		it "should be binary encoding" do
			expect(stream.readline.encoding).to be == Encoding::BINARY
		end
	end
	
	describe '#readlines' do
		before(:each) do
			io << "Hello\nWorld\n"
			io.seek(0)
		end
		
		it "should read multiple lines" do
			expect(stream.readlines).to be == ["Hello", "World"]
		end
		
		it "should be binary encoding" do
			expect(stream.readlines.first.encoding).to be == Encoding::BINARY
		end
	end
end
