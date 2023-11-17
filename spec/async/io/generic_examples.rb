# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2021, by Aurora Nockert.

RSpec.shared_examples Async::IO::Generic do |ignore_methods|
	# let(:instance_methods) {described_class.wrapped_klass.public_instance_methods(false) - (ignore_methods || [])}
	# let(:wrapped_instance_methods) {described_class.public_instance_methods}
	
	# it "should wrap a class" do
	# 	expect(described_class.wrapped_klass).to_not be_nil
	# end
	
	# it "should wrap underlying instance methods" do
	# 	expect(wrapped_instance_methods.sort).to include(*instance_methods.sort)
	# end
	
	# # This needs to be reviewed in more detail.
	# #
	# # let(:singleton_methods) {described_class.wrapped_klass.singleton_methods(false)}
	# # let(:wrapped_singleton_methods) {described_class.singleton_methods(false)}
	# # 
	# # it "should wrap underlying class methods" do
	# # 	singleton_methods.each do |method|
	# # 		expect(wrapped_singleton_methods).to include(method)
	# # 	end
	# # end
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
	
	context "has the right encoding" do
		it "with a normal read" do
			io.write(data)
			expect(subject.read(1).encoding).to be == Encoding::BINARY
		end
		
		it "with a zero-length read" do
			expect(subject.read(0).encoding).to be == Encoding::BINARY
		end
	end

	context "are not frozen" do
		it "with a normal read" do
			io.write(data)
			expect(subject.read(1).frozen?).to be == false
		end
		
		it "with a zero-length read" do
			expect(subject.read(0).frozen?).to be == false
		end
	end
end
