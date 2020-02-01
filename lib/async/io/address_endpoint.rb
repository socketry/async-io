# frozen_string_literal: true

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

require_relative 'endpoint'

module Async
	module IO
		# This class will open and close the socket automatically.
		class AddressEndpoint < Endpoint
			def initialize(address, **options)
				super(**options)
				
				@address = address
			end
			
			def to_s
				"\#<#{self.class} #{@address.inspect}>"
			end
			
			attr :address
			
			# Bind a socket to the given address. If a block is given, the socket will be automatically closed when the block exits.
			# @yield [Socket] the bound socket
			# @return [Socket] the bound socket
			def bind(&block)
				Socket.bind(@address, **@options, &block)
			end
			
			# Connects a socket to the given address. If a block is given, the socket will be automatically closed when the block exits.
			# @return [Socket] the connected socket
			def connect(&block)
				Socket.connect(@address, **@options, &block)
			end
		end
	end
end
