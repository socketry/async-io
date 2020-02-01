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

require_relative "../host_endpoint"
require_relative "../socket_endpoint"
require_relative "../ssl_endpoint"

module Async
	module IO
		class Endpoint
			def self.try_convert(specification)
				if specification.is_a? self
					specification
				elsif specification.is_a? Array
					self.send(*specification)
				elsif specification.is_a? String
					self.parse(specification)
				elsif specification.is_a? ::BasicSocket
					self.socket(specification)
				elsif specification.is_a? Generic
					self.new(specification)
				else
					raise ArgumentError.new("Not sure how to convert #{specification} to endpoint!")
				end
			end
			
			# Generate a list of endpoints from an array.
			def self.each(specifications, &block)
				return to_enum(:each, specifications) unless block_given?
				
				specifications.each do |specification|
					yield try_convert(specification)
				end
			end
		end
	end
end
