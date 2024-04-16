# frozen_string_literal: true

require_relative "lib/async/io/version"

Gem::Specification.new do |spec|
	spec.name = "async-io"
	spec.version = Async::IO::VERSION
	
	spec.summary = "Provides support for asynchonous TCP, UDP, UNIX and SSL sockets."
	spec.authors = ["Samuel Williams", "Olle Jonsson", "Benoit Daloze", "Thibaut Girka", "Hal Brodigan", "Janko Marohnić", "Aurora Nockert", "Bruno Sutic", "Cyril Roelandt", "Hasan Kumar", "Jiang Jinyang", "Maruth Goyal", "Patrik Wenger"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/async-io"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/async-io/",
		"source_code_uri" => "https://github.com/socketry/async-io.git",
	}
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_dependency "async"
end
