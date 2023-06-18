# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require 'async'

require_relative "io/generic"
require_relative "io/socket"
require_relative "io/version"
require_relative "io/endpoint"

module Async
	module IO
		def self.file_descriptor_limit
			Process.getrlimit(Process::RLIMIT_NOFILE).first
		end
		
		def self.buffer?
			::IO.const_defined?(:Buffer)
		end
	end
end
