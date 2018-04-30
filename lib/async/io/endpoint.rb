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
			def initialize(**options)
				@options = options
			end
			
			attr :options
			
			def hostname
				@options[:hostname]
			end
			
			def self.parse(string, **options)
				uri = URI.parse(string)
				
				self.send(uri.scheme, uri.host, uri.port, **options)
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
	end
end

require 'host_endpoint'
require 'socket_endpoint'
