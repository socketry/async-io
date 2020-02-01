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

require_relative 'host_endpoint'
require_relative 'ssl_socket'

module Async
	module IO
		class SSLEndpoint < Endpoint
			def initialize(endpoint, **options)
				super(**options)
				
				@endpoint = endpoint
				
				if ssl_context = options[:ssl_context]
					@context = build_context(ssl_context)
				else
					@context = nil
				end
			end
			
			def to_s
				"\#<#{self.class} #{@endpoint}>"
			end
			
			def address
				@endpoint.address
			end
			
			def hostname
				@options[:hostname] || @endpoint.hostname
			end
			
			attr :endpoint
			attr :options
			
			def params
				@options[:ssl_params]
			end
			
			def build_context(context = OpenSSL::SSL::SSLContext.new)
				if params = self.params
					context.set_params(params)
				end
				
				context.setup
				context.freeze
				
				return context
			end
			
			def context
				@context ||= build_context
			end
			
			# Connect to the underlying endpoint and establish a SSL connection.
			# @yield [Socket] the socket which is being connected
			# @return [Socket] the connected socket
			def bind
				if block_given?
					@endpoint.bind do |server|
						yield SSLServer.new(server, context)
					end
				else
					return SSLServer.new(@endpoint.bind, context)
				end
			end
			
			# Connect to the underlying endpoint and establish a SSL connection.
			# @yield [Socket] the socket which is being connected
			# @return [Socket] the connected socket
			def connect(&block)
				SSLSocket.connect(@endpoint.connect, context, hostname, &block)
			end
			
			def each
				return to_enum unless block_given?
				
				@endpoint.each do |endpoint|
					yield self.class.new(endpoint, **@options)
				end
			end
		end
		
		# Backwards compatibility.
		SecureEndpoint = SSLEndpoint
		
		class Endpoint
			# @param args
			# @param ssl_context [OpenSSL::SSL::SSLContext, nil]
			# @param hostname [String, nil]
			# @param options keyword arguments passed through to {Endpoint.tcp}
			#
			# @return [SSLEndpoint]
			def self.ssl(*args, ssl_context: nil, hostname: nil, **options)
				SSLEndpoint.new(self.tcp(*args, **options), ssl_context: ssl_context, hostname: hostname)
			end
		end
	end
end
