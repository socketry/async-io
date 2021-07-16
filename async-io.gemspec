
require_relative "lib/async/io/version"

Gem::Specification.new do |spec|
	spec.name = "async-io"
	spec.version = Async::IO::VERSION
	
	spec.summary = "Provides support for asynchonous TCP, UDP, UNIX and SSL sockets."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/socketry/async-io"
	
	spec.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_dependency "async"
	
	spec.add_development_dependency "async-container", "~> 0.15"
	spec.add_development_dependency "async-rspec", "~> 1.10"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "rack-test"
	spec.add_development_dependency "rspec", "~> 3.6"
end
