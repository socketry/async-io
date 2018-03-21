
RSpec.shared_examples Async::IO::Generic do |ignore_methods|
	let(:instance_methods) {described_class.wrapped_klass.instance_methods(false) - (ignore_methods || [])}
	let(:wrapped_instance_methods) {described_class.instance_methods(false)}
	
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
