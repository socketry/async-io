#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require 'async'
require 'async/io'

require 'benchmark/ips'

def measure(pipe, count)
	i, o = pipe
	
	count.times do
		o.write("Hello World")
		i.read(11)
	end
end

Benchmark.ips do |benchmark|
	benchmark.time = 10
	benchmark.warmup = 2
	
	benchmark.report("Async::IO.pipe") do |count|
		Async do |task|
			measure(::Async::IO.pipe, count)
		end
	end
	
	benchmark.report("IO.pipe") do |count|
		Async do |task|
			measure(::IO.pipe, count)
		end
	end
	
	benchmark.compare!
end
