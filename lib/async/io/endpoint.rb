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

require_relative 'address'
require_relative 'socket'
require 'uri'

module Async
	module IO
		class Endpoint
			def self.parse(string, **options)
				uri = URI.parse(string)
				
				self.send(uri.scheme, uri.host, uri.port, **options)
			end
			
			# args: nodename, service, family, socktype, protocol, flags
			def self.tcp(*args, **options)
				args[3] = ::Socket::SOCK_STREAM
				
				HostEndpoint.new(args, **options)
			end
			
			def self.udp(*args, **options)
				args[3] = ::Socket::SOCK_DGRAM
				
				HostEndpoint.new(args, **options)
			end
			
			def self.unix(*args, **options)
				AddressEndpoint.new(Address.unix(*args), **options)
			end
			
			def self.ssl(*args, **options)
				SecureEndpoint.new(self.tcp(*args, **options), **options)
			end
			
			def self.try_convert(specification)
				if specification.is_a? self
					specification
				elsif specification.is_a? Array
					self.send(*specification)
				elsif specification.is_a? String
					self.parse(specification)
				elsif specification.is_a? ::BasicSocket
					SocketEndpoint.new(specification)
				elsif specification.is_a? Generic
					Endpoint.new(specification)
				else
					raise ArgumentError.new("Not sure how to convert #{specification} to endpoint!")
				end
			end
			
			# Generate a list of endpoint from an array.
			def self.each(specifications, &block)
				return to_enum(:each, specifications) unless block_given?
				
				specifications.each do |specification|
					yield try_convert(specification)
				end
			end
			
			def each
				return to_enum unless block_given?
				
				yield self
			end
			
			def accept(backlog = Socket::SOMAXCONN, &block)
				bind do |server|
					server.listen(backlog)
					
					server.accept_each(&block)
				end
			end
		end
		
		class HostEndpoint < Endpoint
			def initialize(specification, **options)
				@specification = specification
				@options = options
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
		
		# This class will open and close the socket automatically.
		class AddressEndpoint < Endpoint
			def initialize(address, **options)
				@address = address
				@options = options
			end
			
			attr :address
			attr :options
			
			def bind(&block)
				Socket.bind(@address, **@options, &block)
			end
			
			def connect(&block)
				Socket.connect(@address, **@options, &block)
			end
		end
		
		class SecureEndpoint < Endpoint
			def initialize(endpoint, **options)
				@endpoint = endpoint
				@options = options
			end
			
			attr :endpoint
			attr :options
			
			def hostname
				@options[:hostname]
			end
			
			def params
				@options[:ssl_params]
			end
			
			def context
				if context = @options[:ssl_context]
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
			
			def bind
				@endpoint.bind do |server|
					yield SSLServer.new(server, context)
				end
			end
			
			def connect(&block)
				SSLSocket.connect(@endpoint.connect, context, hostname, &block)
			end
			
			def each
				return to_enum unless block_given?
				
				@endpoint.each do |endpoint|
					yield self.class.new(endpoint, @options)
				end
			end
		end
		
		# This class doesn't exert ownership over the specified socket, wraps a native ::IO.
		class SocketEndpoint < Endpoint
			def initialize(socket)
				# This socket should already be in the required state.
				@socket = Async::IO.try_convert(socket)
			end
			
			attr :socket
			
			def bind(&block)
				if block_given?
					yield @socket
				else
					return @socket
				end
			end
			
			def connect(&block)
				if block_given?
					yield @socket
				else
					return @socket
				end
			end
		end
	end
end
