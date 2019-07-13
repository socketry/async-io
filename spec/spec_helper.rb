
require 'covered/rspec'
require "async/rspec"

require_relative 'addrinfo'

class RSpec::Core::Formatters::DocumentationFormatter
	def message(notification)
		output.puts "#{current_indentation}#{notification.message}"
	end
end

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
