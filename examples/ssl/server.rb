#!/usr/bin/env ruby

require 'async'
require 'async/io'
require 'async/io/stream'

key_file = File.join(__dir__,'key.pem')
cert_file = File.join(__dir__,'cert.crt')

ssl_context = OpenSSL::SSL::SSLContext.new
ssl_context.key = OpenSSL::PKey::RSA.new(File.read(key_file))
ssl_context.cert = OpenSSL::X509::Certificate.new(File.read(cert_file))

endpoint = Async::IO::Endpoint.ssl('localhost',5678, ssl_context: ssl_context)

Async do |async|
	endpoint.accept do |peer|
		stream = Async::IO::Stream.new(peer)

		while line = stream.gets
			puts "received: #{line}"
			stream.puts "you sent: #{line}"
		end
	end
end
