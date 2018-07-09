
# This is useful for specs, but I hesitate to monkey patch a core class in the library itself.
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
