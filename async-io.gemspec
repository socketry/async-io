# coding: utf-8
require_relative 'lib/async/io/version'

Gem::Specification.new do |spec|
	spec.name          = "async-io"
	spec.version       = Async::IO::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]

	spec.summary       = "Provides support for asynchonous TCP, UDP, UNIX and SSL sockets."
	spec.homepage      = "https://github.com/socketry/async-io"

	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]
	spec.has_rdoc      = "yard"

	spec.add_dependency "async", "~> 1.0"
	spec.add_development_dependency "async-rspec", "~> 1.2"

	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rake", "~> 10.0"
	spec.add_development_dependency "rspec", "~> 3.0"
end
