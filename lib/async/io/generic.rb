# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2021, by Aurora Nockert.

module Async
	module IO
		# The default block size for IO buffers. Defaults to 64KB (typical pipe buffer size).
		BLOCK_SIZE = ENV.fetch('ASYNC_IO_BLOCK_SIZE', 1024*64).to_i
		
		# The maximum read size when appending to IO buffers. Defaults to 8MB.
		MAXIMUM_READ_SIZE = ENV.fetch('ASYNC_IO_MAXIMUM_READ_SIZE', BLOCK_SIZE * 128).to_i
		
		# Convert a Ruby ::IO object to a wrapped instance:
		def self.try_convert(io)
			io
		end
		
		def self.pipe
			::IO.pipe
		end
		
		Generic = ::IO
	end
end

class ::IO
	def connected?
		!@io.closed?
	end
end
