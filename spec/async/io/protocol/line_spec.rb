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

require 'async/io/protocol/line'

RSpec.describe Async::IO::Protocol::Line do
	let(:io) {StringIO.new}
	let(:stream) {Async::IO::Stream.new(io)}
	subject {described_class.new(stream, "\n")}
	
	context "default line ending" do
		subject {described_class.new(stream)}
		
		it "should have default eol terminator" do
			expect(subject.eol).to_not be_nil
		end
	end
	
	describe '#write_lines' do
		it "should write line" do
			subject.write_lines "Hello World"
			
			expect(io.string).to be == "Hello World\n"
		end
	end
	
	describe '#read_line' do
		before(:each) do
			io.puts "Hello World"
			io.seek(0)
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
			io << "Hello\nWorld\n"
			io.seek(0)
		end
		
		it "should read multiple lines" do
			expect(subject.read_lines).to be == ["Hello", "World"]
		end
		
		it "should be binary encoding" do
			expect(subject.read_lines.first.encoding).to be == Encoding::BINARY
		end
	end
end
