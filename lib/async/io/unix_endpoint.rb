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

require_relative 'address_endpoint'

module Async
	module IO
		class LockError < RuntimeError
		end
		
		# This class doesn't exert ownership over the specified unix socket and ensures exclusive access by using `flock` where possible.
		class UNIXEndpoint < AddressEndpoint
			def initialize(path, type, **options)
				super(Address.unix(path, type), **options)
				
				@path = path
			end
			
			def to_s
				"\#<#{self.class} #{@path.inspect}>"
			end
			
			attr :path
			
			def lock_path
				"#{@path}.lock"
			end
			
			def with_lock(path = self.lock_path)
				file = File.open(path, File::RDONLY | File::CREAT, 0600)
				
				if file.flock(File::LOCK_EX | File::LOCK_NB)
					begin
						yield
					ensure
						file.close
						File.unlink(path)
					end
				else
					raise LockError, "Could not acquire file lock: #{path}"
				end
			end
			
			def bind(&block)
				with_lock do
					File.unlink(@path) if File.exist?(@path)
					
					super(&block)
				end
			end
		end
		
		class Endpoint
			def self.unix(path, type = ::Socket::SOCK_STREAM, **options)
				UNIXEndpoint.new(path, type, **options)
			end
		end
	end
end
