source 'https://rubygems.org'

# Specify your gem's dependencies in async-io.gemspec
gemspec

group :development do
	gem 'pry'
	gem 'guard-rspec'
	gem 'guard-yard'
	
	gem 'yard'
end

group :test do
	gem 'benchmark-ips'
	gem 'ruby-prof', platforms: :mri
	
	gem 'simplecov'
	gem 'coveralls', require: false
	
	gem 'async-container'

	gem 'http'
end
