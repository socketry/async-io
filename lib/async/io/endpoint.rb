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
		
		Endpoints = Struct.new(:ordered) do
			include Enumerable
			
			def each(&block)
				return to_enum unless block_given?
				
				Endpoint.each(self.ordered, &block)
			end
			
			def connect
				return to_enum(:connect) unless block_given?
				
				self.each do |endpoint|
					endpoint.connect(&block)
				end
			end
			
			def accept(&block)
				return to_enum(:accept) unless block_given?
				
				self.each do |endpoint|
					endpoint.accept(&block)
				end
			end
			
			def bind
				return to_enum(:bind) unless block_given?
				
				self.each do |endpoint|
					endpoint.bind(&block)
				end
			end
		end
		
		class Endpoint < Struct.new(:specification, :options)
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
				
				# Generate a list of endpoint from an array.
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
				ensure
					server.close
				end
			end
			
			def connect
				yield specification
			end
		end
		
		class HostEndpoint < Endpoint
			def bind(&block)
				return to_enum(:bind) unless block_given?
				
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
				return to_enum(:connect) unless block_given?
				
				Addrinfo.foreach(*specification).each do |address|
					Socket.connect(address, &block)
				end
			end
		end
		
		# This class will open and close the socket automatically.
		class AddressEndpoint < Endpoint
			def bind(&block)
				return to_enum(:bind) unless block_given?
				
				Socket.bind(specification, **options, &block)
			end
			
			def connect(&block)
				return to_enum(:connect) unless block_given?
				
				Socket.connect(specification, &block)
			end
		end
		
		# This class doesn't exert ownership over the specified socket, wraps a native ::IO.
		class SocketEndpoint < Endpoint
			def bind(&block)
				return to_enum(:bind) unless block_given?
				
				yield Socket.new(specification)
			end
			
			def connect(&block)
				return to_enum(:connect) unless block_given?
				
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
				return to_enum(:bind) unless block_given?
				
				specification.bind do |server|
					yield SSLServer.new(server, context)
				end
			end
			
			def connect(&block)
				return to_enum(:connect) unless block_given?
				
				specification.connect do |socket|
					ssl_socket = SSLSocket.wrap(socket, context)
					
					# Used for SNI:
					if hostname = self.hostname
						ssl_socket.hostname = hostname
					end
					
					begin
						ssl_socket.connect
					rescue
						# If the connection fails (e.g. certificates are invalid), the caller never sees the socket, so we close it and raise the exception up the chain.
						ssl_socket.close
						raise
					end
					
					yield ssl_socket
				end
			end
		end
	end
end
