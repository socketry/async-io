#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require "socket"

10.times do
	UNIXSocket.open("./tmp.sock") do |socket|
		socket << "hello\n"
		p socket.read(6)
		socket.close
	end
end
