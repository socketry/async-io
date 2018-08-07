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

require 'async/io/buffer'

RSpec.describe Async::IO::Buffer do
	include_context Async::RSpec::Memory
	
	let!(:string) {"Hello World!".b}
	subject! {described_class.new}
	
	it "should be binary encoding" do
		expect(subject.encoding).to be Encoding::BINARY
	end
	
	it "should not allocate strings when concatenating" do
		expect do
			subject << string
		end.to limit_allocations.of(String, size: 0, count: 0)
	end
	
	it "can append unicode strings to binary buffer" do
		2.times do
			subject << "Føøbar"
		end
		
		expect(subject).to eq "FøøbarFøøbar".b
	end
end
