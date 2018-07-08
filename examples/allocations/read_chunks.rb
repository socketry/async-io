#!/usr/bin/env ruby

require_relative 'memory'

require_relative "../../lib/async/io/stream"
require "stringio"

measure_memory("Stream setup") do
	@io = StringIO.new("a" * (50*1024*1024))
	@stream = Async::IO::Stream.new(@io)
end # 50.0 MB

measure_memory("Read all chunks") do
	while chunk = @stream.read_partial
		chunk.clear
	end
end # 0.5 MB
