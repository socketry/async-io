#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'socket'
require 'openssl'

server = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
server.bind(Addrinfo.tcp('127.0.0.1', 4433))
server.listen(128)

ssl_server = OpenSSL::SSL::SSLServer.new(server, OpenSSL::SSL::SSLContext.new)

puts ssl_server.addr

# openssl/ssl.rb:234:in `addr': undefined method `addr' for #<Socket:fd 8> (NoMethodError)
