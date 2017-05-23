# coding: utf-8
require_relative 'lib/async/io/version'

Gem::Specification.new do |spec|
	spec.name          = "async-io"
	spec.version       = Async::IO::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]

	spec.summary       = "Provides support for asynchonous TCP, UDP, UNIX and SSL sockets."
	spec.homepage      = "https://github.com/socketry/async-io"

	spec.require_paths = ["lib"]

	spec.add_dependency "async", "~> 0.14"
	spec.add_development_dependency "async-rspec", "~> 1.0"

	spec.add_development_dependency "bundler", "~> 1.13"
	spec.add_development_dependency "rake", "~> 10.0"
	spec.add_development_dependency "rspec", "~> 3.0"
end
