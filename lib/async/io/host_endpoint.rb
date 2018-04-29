# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'endpoint'

module Async
	module IO
		class HostEndpoint < Endpoint
			def initialize(specification, **options)
				super(**options)
				
				@specification = specification
			end
			
			def to_s
				"\#<#{self.class} #{@specification.inspect}>"
			end
			
			def hostname
				@specification.first
			end
			
			def connect(&block)
				last_error = nil
				
				Addrinfo.foreach(*@specification).each do |address|
					begin
						return Socket.connect(address, **@options, &block)
					rescue
						last_error = $!
					end
				end
				
				raise last_error
			end
			
			def bind(&block)
				Addrinfo.foreach(*@specification) do |address|
					Socket.bind(address, **@options, &block)
				end
			end
			
			def each
				return to_enum unless block_given?
				
				Addrinfo.foreach(*@specification).each do |address|
					yield AddressEndpoint.new(address, **@options)
				end
			end
		end
		
		class Endpoint
			# args: nodename, service, family, socktype, protocol, flags
			def self.tcp(*args, **options)
				args[3] = ::Socket::SOCK_STREAM
				
				HostEndpoint.new(args, **options)
			end
			
			def self.udp(*args, **options)
				args[3] = ::Socket::SOCK_DGRAM
				
				HostEndpoint.new(args, **options)
			end
		end
	end
end
