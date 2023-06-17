# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'async/task'

module Async
	module IO
		module Server
			def accept_each(timeout: nil, task: Task.current)
				task.annotate "accepting connections #{self.local_address.inspect} [fd=#{self.fileno}]"
				
				callback = lambda do |io, address|
					yield io, address, task: task
				end
				
				while true
					self.accept(timeout: timeout, task: task, &callback)
				end
			end
		end
	end
end
