# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'async/rspec/buffer'
require 'async/io/stream'

RSpec.shared_context Async::IO::Stream do
	include_context Async::RSpec::Buffer
	subject {described_class.new(buffer)}
	let(:io) {subject.io}
end
