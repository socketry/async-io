# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

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
