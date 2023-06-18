# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

def measure_memory(annotation = "Memory allocated")
	GC.disable
	
	start_memory = `ps -p #{Process::pid} -o rss`.split("\n")[1].chomp.to_i

	yield
	
ensure
	end_memory = `ps -p #{Process::pid} -o rss`.split("\n")[1].chomp.to_i
	memory_usage = (end_memory - start_memory).to_f / 1024
	
	puts "#{memory_usage.round(1)} MB: #{annotation}"
	GC.enable
end
