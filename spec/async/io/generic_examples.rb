# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

RSpec.shared_examples Async::IO::Generic do |ignore_methods|
	let(:instance_methods) {described_class.wrapped_klass.public_instance_methods(false) - (ignore_methods || [])}
	let(:wrapped_instance_methods) {described_class.public_instance_methods}
	
	it "should wrap a class" do
		expect(described_class.wrapped_klass).to_not be_nil
	end
	
	it "should wrap underlying instance methods" do
		expect(wrapped_instance_methods.sort).to include(*instance_methods.sort)
	end
	
	# This needs to be reviewed in more detail.
	#
	# let(:singleton_methods) {described_class.wrapped_klass.singleton_methods(false)}
	# let(:wrapped_singleton_methods) {described_class.singleton_methods(false)}
	# 
	# it "should wrap underlying class methods" do
	# 	singleton_methods.each do |method|
	# 		expect(wrapped_singleton_methods).to include(method)
	# 	end
	# end
end

RSpec.shared_examples Async::IO do
	let(:data) {"Hello World!"}
	
	it "should read data" do
		io.write(data)
		expect(subject.read(data.bytesize)).to be == data
	end
	
	it "should read less than available data" do
		io.write(data)
		expect(subject.read(1)).to be == data[0]
	end
	
	it "should read all available data" do
		io.write(data)
		io.close_write
		
		expect(subject.read(data.bytesize * 2)).to be == data
	end
	
	it "should read all available data" do
		io.write(data)
		io.close_write
		
		expect(subject.read).to be == data
	end
end
