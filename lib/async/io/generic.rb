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

require 'async/wrapper'
require 'forwardable'

module Async
	module IO
		# Convert a Ruby ::IO object to a wrapped instance:
		def self.try_convert(io, &block)
			Generic::WRAPPERS[io.class].wrap(io, &block)
		end
		
		# Represents an asynchronous IO within a reactor.
		class Generic < Wrapper
			extend Forwardable
			
			WRAPPERS = {}
			
			class << self
				# @!macro [attach] wrap_blocking_method
				#   @method $1
				#   Invokes `$2` on the underlying {io}. If the operation would block, the current task is paused until the operation can succeed, at which point it's resumed and the operation is completed.
				def wrap_blocking_method(new_name, method_name, invert: true)
					define_method(new_name) do |*args|
						async_send(method_name, *args)
					end
					
					if invert
						# We define the original _nonblock method to call the async variant. We ignore options.
						# define_method(method_name) do |*args, **options|
						# 	self.__send__(new_name, *args)
						# end
						def_delegators :@io, method_name
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
			
			wraps ::IO, :external_encoding, :internal_encoding, :autoclose?, :autoclose=, :pid, :stat, :binmode, :flush, :set_encoding, :to_io, :to_i, :reopen, :fileno, :fsync, :fdatasync, :sync, :sync=, :tell, :seek, :rewind, :pos, :pos=, :eof, :eof?, :close_on_exec?, :close_on_exec=, :closed?, :close_read, :close_write, :isatty, :tty?, :binmode?, :sysseek, :advise, :ioctl, :fcntl
			
			# @example
			#   data = io.read(512)
			wrap_blocking_method :read, :read_nonblock
			
			# @example
			#   io.write("Hello World")
			wrap_blocking_method :write, :write_nonblock
			
			protected
			
			if RUBY_ENGINE == "ruby" and RUBY_VERSION >= "2.3"
				def async_send(*args)
					async do
						@io.__send__(*args, exception: false)
					end
				end
				
				def async
					while true
						result = yield
						
						case result
						when :wait_readable
							wait_readable
						when :wait_writable
							wait_writable
						else
							return result
						end
					end
				end
			elsif RUBY_ENGINE == "ruby" and RUBY_VERSION >= "2.1"
				def async_send(*args)
					async do
						@io.__send__(*args)
					end
				end
				
				def async
					while true
						begin
							return yield
						rescue ::IO::WaitReadable, ::IO::EAGAINWaitReadable
							wait_readable
						rescue ::IO::WaitWritable, ::IO::EAGAINWaitWritable
							wait_writable
						end
					end
				end
			else
				# This is also correct for Rubinius.
				def async_send(*args)
					async do
						@io.__send__(*args)
					end
				end
				
				def async
					while true
						begin
							return yield
						rescue ::IO::WaitReadable
							wait_readable
						rescue ::IO::WaitWritable
							wait_writable
						end
					end
				end
			end
		end
	end
end
