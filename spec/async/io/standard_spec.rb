# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'async/io/standard'

RSpec.describe Async::IO::STDIN do
	include_context Async::RSpec::Reactor
	
	it "should be able to read" do
		expect(subject.read(0)).to be == ""
	end
end

RSpec.describe Async::IO::STDOUT do
	include_context Async::RSpec::Reactor
	
	it "should be able to write" do
		expect(subject.write("")).to be == 0
	end
end

RSpec.describe Async::IO::STDERR do
	include_context Async::RSpec::Reactor
	
	it "should be able to write" do
		expect(subject.write("")).to be == 0
	end
end
