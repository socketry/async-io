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
				
				# args: nodename, service, family, socktype, protocol, flags
				def tcp(*args, **options)
					args[3] = ::Socket::SOCK_STREAM
					
					HostEndpoint.new(args, **options)
				end
				
				def udp(*args, **options)
					args[3] = ::Socket::SOCK_DGRAM
					
					HostEndpoint.new(args, **options)
				end
				
				def unix(*args, **options)
					AddressEndpoint.new(Address.unix(*args), **options)
				end
				
				def ssl(*args, **options)
					SecureEndpoint.new(self.tcp(*args, **options), **options)
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
						elsif specification.is_a? ::BasicSocket
							yield SocketEndpoint.new(specification)
						elsif specification.is_a? Generic
							yield Endpoint.new(specification)
						else
							raise ArgumentError.new("Not sure how to convert #{specification} to endpoint!")
						end
					end
				end
			end
			
			def initialize(specification, **options)
				super(specification, options)
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
		
		class HostEndpoint < Endpoint
			def bind(&block)
				task = Task.current
				tasks = []
				
				task.annotate("binding to #{specification.inspect}")
				
				Addrinfo.foreach(*specification).each do |address|
					tasks << task.async do
						Socket.bind(address, **options, &block)
					end
				end
				
				tasks.each(&:wait)
			end
			
			def connect(&block)
				last_error = nil
				
				Addrinfo.foreach(*specification).each do |address|
					begin
						return Socket.connect(address, &block)
					rescue
						last_error = $!
					end
				end
				
				raise last_error
			end
		end
		
		# This class will open and close the socket automatically.
		class AddressEndpoint < Endpoint
			def bind(&block)
				Socket.bind(specification, **options, &block)
			end
			
			def connect(&block)
				Socket.connect(specification, &block)
			end
		end
		
		# This class doesn't exert ownership over the specified socket, wraps a native ::IO.
		class SocketEndpoint < Endpoint
			def bind(&block)
				yield Socket.new(specification)
			end
			
			def connect(&block)
				yield Async::IO.try_convert(specification)
			end
		end
		
		class SecureEndpoint < Endpoint
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
