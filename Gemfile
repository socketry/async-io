# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in async-io.gemspec
gemspec

group :development do
	gem 'pry'
	gem 'guard-rspec'
	
	gem 'bake-bundler'
end

group :test do
	gem 'benchmark-ips'
	gem 'ruby-prof', platforms: :mri
	
	gem 'http'
end
