# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.
# Copyright, 2019, by Olle Jonsson.

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
					@endpoint.bind.map do |server|
						SSLServer.new(server, context)
					end
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
