#!/usr/bin/env ruby

require_relative 'memory'

string = nil

measure_memory("Initial allocation") do
	string = "a" * 5*1024*1024
	string.freeze
end # => 5.0 MB

measure_memory("Byteslice from start to middle") do
	# Why does this need to allocate memory? Surely it can share the original allocation?
	x = string.byteslice(0, string.bytesize / 2)
end # => 2.5 MB

measure_memory("Byteslice from middle to end") do
	string.byteslice(string.bytesize / 2, string.bytesize)
end # => 0.0 MB

measure_memory("Slice! from start to middle") do
	string.dup.slice!(0, string.bytesize / 2)
end # => 7.5 MB

measure_memory("Byte slice into two halves") do
	head = string.byteslice(0, string.bytesize / 2) # 2.5 MB
	remainder = string.byteslice(string.bytesize / 2, string.bytesize) # Shared
end # 2.5 MB
