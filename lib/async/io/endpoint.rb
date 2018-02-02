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
			include Comparable
			
			class << self
				def parse(string, **options)
					uri = URI.parse(string)
					self.send(uri.scheme, uri.host, uri.port, **options)
				end
				
				def tcp(*args, **options)
					AddressEndpoint.new(Address.tcp(*args), **options)
				end
				
				def udp(*args, **options)
					AddressEndpoint.new(Address.udp(*args), **options)
				end
				
				def unix(*args, **options)
					AddressEndpoint.new(Address.unix(*args), **options)
				end
				
				def ssl(*args, **options)
					SecureEndpoint.new(Endpoint.tcp(*args, **options), **options)
				end
				
				# Generate a list of endpoints from an array.
				def each(specifications, &block)
					return to_enum(:each, specifications) unless block_given?
					
					specifications.each do |specification|
						if specification.is_a? self
							yield specification
						elsif specification.is_a? Array
							yield self.send(*specification)
						elsif specification.is_a? String
							yield self.parse(specification)
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
			
			def bind
				yield specification
			end
			
			def accept(&block)
				backlog = self.options.fetch(:backlog, Socket::SOMAXCONN)
				
				bind do |server|
					server.listen(backlog)
					server.accept_each(&block)
				end
			end
			
			def connect
				yield specification
			end
		end
		
		# This class will open and close the socket automatically.
		class AddressEndpoint < Endpoint
			def address
				specification
			end
			
			def bind(&block)
				Socket.bind(address, **options, &block)
			end
			
			def connect(&block)
				Socket.connect(address, &block)
			end
		end
		
		# This class doesn't exert ownership over the specified socket.
		class SocketEndpoint < Endpoint
			def address
				specification.local_address
			end
			
			def bind(&block)
				yield Socket.new(specification, **options)
			end
			
			def connect(&block)
				yield Async::IO.try_convert(specification)
			end
		end
		
		class SecureEndpoint < Endpoint
			def address
				specification.address
			end
			
			def hostname
				options[:hostname]
			end
			
			def params
				options[:ssl_params]
			end
			
			def context
				if context = options[:ssl_context]
					if params = self.params
						context = context.dup
						context.set_params(params)
					end
				else
					context = ::OpenSSL::SSL::SSLContext.new
					
					if params = self.params
						context.set_params(params)
					end
				end
				
				return context
			end
			
			def bind(&block)
				specification.bind do |server|
					yield SSLServer.new(server, context)
				end
			end
			
			def connect(&block)
				specification.connect do |socket|
					ssl_socket = SSLSocket.connect_socket(socket, context)
					
					# Used for SNI:
					if hostname = self.hostname
						ssl_socket.hostname = hostname
					end
					
					ssl_socket.connect
					
					yield ssl_socket
				end
			end
		end
	end
end
