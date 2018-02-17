
if ENV['COVERAGE'] || ENV['TRAVIS']
	begin
		require 'simplecov'
		
		SimpleCov.start do
			add_filter "/spec/"
		end
		
		if ENV['TRAVIS']
			require 'coveralls'
			Coveralls.wear!
		end
	rescue LoadError
		warn "Could not load simplecov: #{$!}"
	end
end

require "bundler/setup"
require "async/io"

puts "Running on #{RUBY_VERSION.inspect} #{RUBY_ENGINE.inspect}"

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

# Shared rspec helpers:
require "async/rspec"

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
