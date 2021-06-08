# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development do
	gem "async-container", "~> 0.15"
	gem "async-rspec", "~> 1.10"
	gem "bake"
	gem "bake-bundler"
	gem "bake-modernize" unless defined?(JRUBY_VERSION)
	gem "bundler"
	gem "covered"
	gem "rspec", "~> 3.0"
end

group :test do
	gem 'benchmark-ips'
	gem 'ruby-prof', platforms: :mri

	gem 'http'
end
