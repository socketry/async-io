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

require_relative 'address_endpoint'

module Async
	module IO
		class HostEndpoint < Endpoint
			def initialize(specification, **options)
				super(**options)
				
				@specification = specification
			end
			
			def to_s
				nodename, service, family, socktype, protocol, flags = @specification
				
				"\#<#{self.class} name=#{nodename.inspect} service=#{service.inspect} family=#{family.inspect} type=#{socktype.inspect} protocol=#{protocol.inspect} flags=#{flags.inspect}>"
			end
			
			def hostname
				@specification.first
			end
			
			# Try to connect to the given host by connecting to each address in sequence until a connection is made.
			# @yield [Socket] the socket which is being connected, may be invoked more than once
			# @return [Socket] the connected socket
			# @raise if no connection could complete successfully
			def connect(&block)
				last_error = nil
				
				Addrinfo.foreach(*@specification) do |address|
					begin
						return Socket.connect(address, **@options, &block)
					# This is a little bit risky. In theory, what it is supposed to do is catch the failed connection, and try the next address. In practice, it can catch other kinds of failures. Ideally, it only applies to `#connect`, but it also applies to what's executed in `&block`.
					rescue
						last_error = $!
					end
				end
				
				raise last_error
			end
			
			# Invokes the given block for every address which can be bound to.
			# @yield [Socket] the bound socket
			# @return [Array<Socket>] an array of bound sockets
			def bind(&block)
				Addrinfo.foreach(*@specification).collect do |address|
					Socket.bind(address, **@options, &block)
				end
			end
			
			# @yield [AddressEndpoint] address endpoints by resolving the given host specification
			def each
				return to_enum unless block_given?
				
				Addrinfo.foreach(*@specification) do |address|
					yield AddressEndpoint.new(address, **@options)
				end
			end
		end
		
		class Endpoint
			# @param args nodename, service, family, socktype, protocol, flags. `socktype` will be set to Socket::SOCK_STREAM.
			# @param options keyword arguments passed on to {HostEndpoint#initialize}
			#
			# @return [HostEndpoint]
			def self.tcp(*args, **options)
				args[3] = ::Socket::SOCK_STREAM
				
				HostEndpoint.new(args, **options)
			end

			# @param args nodename, service, family, socktype, protocol, flags. `socktype` will be set to Socket::SOCK_DGRAM.
			# @param options keyword arguments passed on to {HostEndpoint#initialize}
			#
			# @return [HostEndpoint]
			def self.udp(*args, **options)
				args[3] = ::Socket::SOCK_DGRAM
				
				HostEndpoint.new(args, **options)
			end
		end
	end
end
