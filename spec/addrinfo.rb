# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

class Addrinfo
	def == other
		self.to_s == other.to_s
	end
	
	def != other
		self.to_s != other.to_s
	end
	
	def <=> other
		self.to_s <=> other.to_s
	end
end
