# frozen_string_literal: true

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
		# Endpoints represent a way of connecting or binding to an address.
		class Endpoint
			def initialize(**options)
				@options = options.freeze
			end
			
			def with(**options)
				dup = self.dup
				
				dup.options = @options.merge(options)
				
				return dup
			end
			
			attr_accessor :options
			
			# @return [String] The hostname of the bound socket.
			def hostname
				@options[:hostname]
			end
			
			# If `SO_REUSEPORT` is enabled on a socket, the socket can be successfully bound even if there are existing sockets bound to the same address, as long as all prior bound sockets also had `SO_REUSEPORT` set before they were bound.
			# @return [Boolean, nil] The value for `SO_REUSEPORT`.
			def reuse_port
				@options[:reuse_port]
			end
			
			# If `SO_REUSEADDR` is enabled on a socket prior to binding it, the socket can be successfully bound unless there is a conflict with another socket bound to exactly the same combination of source address and port. Additionally, when set, binding a socket to the address of an existing socket in `TIME_WAIT` is not an error.
			# @return [Boolean] The value for `SO_REUSEADDR`.
			def reuse_address
				@options[:reuse_address]
			end
			
			# Controls SO_LINGER. The amount of time the socket will stay in the `TIME_WAIT` state after being closed.
			# @return [Integer, nil] The value for SO_LINGER.
			def linger
				@options[:linger]
			end
			
			# @return [Numeric] The default timeout for socket operations.
			def timeout
				@options[:timeout]
			end
			
			# @return [Address] the address to bind to before connecting.
			def local_address
				@options[:local_address]
			end
			
			# Endpoints sometimes have multiple paths.
			# @yield [Endpoint] Enumerate all discrete paths as endpoints.
			def each
				return to_enum unless block_given?
				
				yield self
			end
			
			# Accept connections from the specified endpoint.
			# @param backlog [Integer] the number of connections to listen for.
			def accept(backlog = Socket::SOMAXCONN, &block)
				bind do |server|
					server.listen(backlog)
					
					server.accept_each(&block)
				end
			end
			
			# Map all endpoints by invoking `#bind`.
			# @yield the bound wrapper.
			def bound
				wrappers = []
				
				self.each do |endpoint|
					wrapper = endpoint.bind
					wrappers << wrapper
					
					yield wrapper
				end
				
				return wrappers
			ensure
				wrappers.each(&:close) if $!
			end
			
			# Create an Endpoint instance by URI scheme. The host and port of the URI will be passed to the Endpoint factory method, along with any options.
			#
			# @param string [String] URI as string. Scheme will decide implementation used.
			# @param options keyword arguments passed through to {#initialize}
			#
			# @see Endpoint.ssl ssl - invoked when parsing a URL with the ssl scheme "ssl://127.0.0.1"
			# @see Endpoint.tcp tcp - invoked when parsing a URL with the tcp scheme: "tcp://127.0.0.1"
			# @see Endpoint.udp udp - invoked when parsing a URL with the udp scheme: "udp://127.0.0.1"
			# @see Endpoint.unix unix - invoked when parsing a URL with the unix scheme: "unix://127.0.0.1"
			def self.parse(string, **options)
				uri = URI.parse(string)
				
				self.public_send(uri.scheme, uri.host, uri.port, **options)
			end
		end
	end
end
