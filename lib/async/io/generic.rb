# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2021, by Aurora Nockert.
# Copyright, 2023, by Patrik Wenger.

require 'async/wrapper'
require 'forwardable'

module Async
	module IO
		# The default block size for IO buffers. Defaults to 64KB (typical pipe buffer size).
		BLOCK_SIZE = ENV.fetch('ASYNC_IO_BLOCK_SIZE', 1024*64).to_i
		
		# The maximum read size when appending to IO buffers. Defaults to 8MB.
		MAXIMUM_READ_SIZE = ENV.fetch('ASYNC_IO_MAXIMUM_READ_SIZE', BLOCK_SIZE * 128).to_i
		
		# Convert a Ruby ::IO object to a wrapped instance:
		def self.try_convert(io, &block)
			if wrapper_class = Generic::WRAPPERS[io.class]
				wrapper_class.new(io, &block)
			else
				raise ArgumentError.new("Unsure how to wrap #{io.class}!")
			end
		end
		
		def self.pipe
			::IO.pipe.map(&Generic.method(:new))
		end
		
		# Represents an asynchronous IO within a reactor.
		class Generic < Wrapper
			extend Forwardable
			
			WRAPPERS = {}
			
			class << self
				# @!macro [attach] wrap_blocking_method
				#   @method $1
				#   Invokes `$2` on the underlying {io}. If the operation would block, the current task is paused until the operation can succeed, at which point it's resumed and the operation is completed.
				def wrap_blocking_method(new_name, method_name, invert: true, &block)
					if block_given?
						define_method(new_name, &block)
					else
						define_method(new_name) do |*args|
							async_send(method_name, *args)
						end
					end
					
					if invert
						# We wrap the original _nonblock method, ignoring options.
						define_method(method_name) do |*args, exception: false|
							async_send(method_name, *args)
						end
					end
				end
				
				attr :wrapped_klass
				
				def wraps(klass, *additional_methods)
					@wrapped_klass = klass
					WRAPPERS[klass] = self
					
					# These are methods implemented by the wrapped class, that we aren't overriding, that may be of interest:
					# fallback_methods = klass.instance_methods(false) - instance_methods
					# puts "Forwarding #{klass} methods #{fallback_methods} to @io"
					
					def_delegators :@io, *additional_methods
				end
				
				# Instantiate a wrapped instance of the class, and optionally yield it to a given block, closing it afterwards.
				def wrap(*args)
					wrapper = self.new(@wrapped_klass.new(*args))
					
					return wrapper unless block_given?
					
					begin
						yield wrapper
					ensure
						wrapper.close
					end
				end
			end
			
			wraps ::IO, :external_encoding, :internal_encoding, :autoclose?, :autoclose=, :pid, :stat, :binmode, :flush, :set_encoding, :set_encoding_by_bom, :to_path, :to_io, :to_i, :reopen, :fileno, :fsync, :fdatasync, :sync, :sync=, :tell, :seek, :rewind, :path, :pos, :pos=, :eof, :eof?, :close_on_exec?, :close_on_exec=, :closed?, :close_read, :close_write, :isatty, :tty?, :binmode?, :sysseek, :advise, :ioctl, :fcntl, :nread, :ready?, :pread, :pwrite, :pathconf
			
			# Read the specified number of bytes from the input stream. This is fast path.
			# @example
			#   data = io.sysread(512)
			wrap_blocking_method :sysread, :read_nonblock
			
			alias readpartial read_nonblock
			
			# Read `length` bytes of data from the underlying I/O. If length is unspecified, read everything.
			def read(length = nil, buffer = nil)
				if buffer
					buffer.clear
				else
					buffer = String.new
				end
				
				if length
					return String.new(encoding: Encoding::BINARY) if length <= 0
					
					# Fast path:
					if buffer = self.sysread(length, buffer)
						
						# Slow path:
						while buffer.bytesize < length
							# Slow path:
							if chunk = self.sysread(length - buffer.bytesize)
								buffer << chunk
							else
								break
							end
						end
						
						return buffer
					else
						return nil
					end
				else
					buffer = self.sysread(BLOCK_SIZE, buffer)
					
					while chunk = self.sysread(BLOCK_SIZE)
						buffer << chunk
					end
					
					return buffer
				end
			end
			
			# Write entire buffer to output stream. This is fast path.
			# @example
			#   io.syswrite("Hello World")
			wrap_blocking_method :syswrite, :write_nonblock
			
			def write(buffer)
				# Fast path:
				written = self.syswrite(buffer)
				remaining = buffer.bytesize - written
				
				while remaining > 0
					# Slow path:
					length = self.syswrite(buffer.byteslice(written, remaining))
					
					remaining -= length
					written += length
				end
				
				return written
			end
			
			def << buffer
				write(buffer)
				return self
			end
			
			def dup
				super.tap do |copy|
					copy.timeout = self.timeout
				end
			end
			
			def wait(timeout = self.timeout, mode = :read)
				case mode
				when :read
					wait_readable(timeout)
				when :write
					wait_writable(timeout)
				else
					wait_any(timeout)
				end
			rescue TimeoutError
				return nil
			end
			
			def nonblock
				true
			end
			
			def nonblock= value
				true
			end
			
			def nonblock?
				true
			end
			
			def connected?
				!@io.closed?
			end
			
			def readable?
				@io.readable?
			end
			
			attr_accessor :timeout
			
			protected
			
			def async_send(*arguments, timeout: self.timeout)
				while true
					result = @io.__send__(*arguments, exception: false)
					
					case result
					when :wait_readable
						wait_readable(timeout)
					when :wait_writable
						wait_writable(timeout)
					else
						return result
					end
				end
			end
		end
	end
end
