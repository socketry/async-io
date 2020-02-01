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

require_relative 'endpoint'

module Async
	module IO
		# This class doesn't exert ownership over the specified socket, wraps a native ::IO.
		class SocketEndpoint < Endpoint
			def initialize(socket, **options)
				super(**options)
				
				# This socket should already be in the required state.
				@socket = Async::IO.try_convert(socket)
			end
			
			def to_s
				"\#<#{self.class} #{@socket.inspect}>"
			end
			
			attr :socket
			
			def bind(&block)
				if block_given?
					begin
						yield @socket
					ensure
						@socket.reactor = nil
					end
				else
					return @socket
				end
			end
			
			def connect(&block)
				if block_given?
					begin
						yield @socket
					ensure
						@socket.reactor = nil
					end
				else
					return @socket
				end
			end
		end
		
		class Endpoint
			def self.socket(socket, **options)
				SocketEndpoint.new(socket, **options)
			end
		end
	end
end
