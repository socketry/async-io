#!/usr/bin/env ruby

require_relative "../lib/async/io/stream"
# require "async/io/stream"
require "stringio"

io = StringIO.new("a" * (50*1024*1024))
stream = Async::IO::Stream.new(io)

GC.disable

start_memory = `ps -p #{Process::pid} -o rss`.split("\n")[1].chomp.to_i

while (chunk = stream.read_partial)
	chunk.clear
end

end_memory = `ps -p #{Process::pid} -o rss`.split("\n")[1].chomp.to_i
puts "#{(end_memory - start_memory).to_f / 1024} MB"
