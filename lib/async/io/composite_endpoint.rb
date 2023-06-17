# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require_relative 'endpoint'

module Async
	module IO
		class CompositeEndpoint < Endpoint
			def initialize(endpoints, **options)
				super(**options)
				@endpoints = endpoints
			end
			
			def each(&block)
				@endpoints.each(&block)
			end
			
			def connect(&block)
				error = nil
				
				@endpoints.each do |endpoint|
					begin
						return endpoint.connect(&block)
					rescue => error
					end
				end
				
				raise error
			end
			
			def bind(&block)
				@endpoints.map(&:bind)
			end
		end
		
		class Endpoint
			def self.composite(*endpoints, **options)
				CompositeEndpoint.new(endpoints, **options)
			end
		end
	end
end
