# frozen_string_literal: true

require_relative "lib/async/io/version"

Gem::Specification.new do |spec|
	spec.name = "async-io"
	spec.version = Async::IO::VERSION
	
	spec.summary = "Provides support for asynchonous TCP, UDP, UNIX and SSL sockets."
	spec.authors = ["Samuel Williams", "Olle Jonsson", "Benoit Daloze", "Thibaut Girka", "Janko Marohnić", "Aurora Nockert", "Bruno Sutic", "Cyril Roelandt", "Hal Brodigan", "Jiang Jinyang"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/async-io"
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.2"
	
	spec.add_dependency "async"
	spec.add_dependency "io-endpoint"
	
	spec.add_development_dependency "async-container", "~> 0.15"
	spec.add_development_dependency "async-rspec", "~> 1.10"
	spec.add_development_dependency "bake"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "rack-test"
	spec.add_development_dependency "rspec", "~> 3.6"
end
