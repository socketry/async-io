# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2019, by Olle Jonsson.

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
