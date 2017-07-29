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

require_relative 'socket'
require 'uri'

module Async
	module IO
		Address = Addrinfo
		
		class Endpoint < Struct.new(:specification, :options)
			include ::Socket::Constants
			include Comparable
			
			class << self
				def parse(string, **options)
					uri = URI.parse(string)
					self.send(uri.scheme, uri.host, uri.port, **options)
				end
				
				def tcp(*args, **options)
					self.new(Address.tcp(*args), **options)
				end
				
				def udp(*args, **options)
					self.new(Address.udp(*args), **options)
				end
				
				def unix(*args, **options)
					self.new(Address.unix(*args), **options)
				end
				
				def each(specifications, &block)
					specifications.each do |specification|
						if specification.is_a? self
							yield specification
						elsif specification.is_a? Array
							yield self.send(*specification)
						else
							yield self.new(specification)
						end
					end
				end
			end
			
			def initialize(specification, **options)
				super(specification, options)
			end
			
			def to_sockaddr
				address.to_sockaddr
			end
			
			# This is how addresses are internally converted, e.g. within `Socket#sendto`.
			alias to_str to_sockaddr
			
			def address
				@address ||= case specification
					when Addrinfo
						specification
					when ::BasicSocket, BasicSocket
						specification.local_address
				else
					raise ArgumentError, "Not sure how to convert #{specification} into address!"
				end
			end
			
			# SOCK_STREAM, SOCK_DGRAM, SOCK_RAW, etc.
			def socket_type
				address.socktype
			end
			
			# PF_* eg PF_INET etc, normally identical to AF_* constants.
			def socket_domain
				address.afamily
			end
			
			# IPPROTO_TCP, IPPROTO_UDP, IPPROTO_IPX, etc.
			def socket_protocol
				address.protocol
			end
			
			def bind(&block)
				case specification
				when Addrinfo
					Socket.bind(specification, **options, &block)
				when ::BasicSocket
					yield Socket.new(specification)
				when BasicSocket
					yield specification
				else
					raise ArgumentError, "Not sure how to bind to #{specification}!"
				end
			end
			
			def accept(&block)
				backlog = self.options.fetch(:backlog, SOMAXCONN)
				
				bind do |socket|
					socket.listen(backlog)
					socket.accept_each(&block)
				end
			end
			
			def connect(&block)
				case specification
				when Addrinfo
					Socket.connect(self, &block)
				when ::BasicSocket
					yield Async::IO.try_convert(specification)
				when BasicSocket
					yield specification
				else
					raise ArgumentError, "Not sure how to connect to #{specification}!"
				end
			end
		end
	end
end
