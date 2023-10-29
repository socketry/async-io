# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2018, by Thibaut Girka.
# Copyright, 2021, by Olle Jonsson.

source 'https://rubygems.org'

gemspec

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"
	
	gem "utopia-project"
end

group :test do
	gem "bake-test"
	gem "bake-test-external"
	
	gem 'benchmark-ips'
	
	gem 'http'
end
