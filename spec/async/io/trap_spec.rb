# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'async/io/trap'

RSpec.describe Async::IO::Trap do
	include_context Async::RSpec::Reactor
	
	subject {described_class.new(:USR2)}
	
	it "can ignore signal" do
		subject.ignore!
		
		Process.kill(:USR2, Process.pid)
	end
	
	it "should wait for signal" do
		trapped = false
		
		waiting_task = reactor.async do
			subject.wait do
				trapped = true
				break
			end
		end
		
		subject.trigger
		
		waiting_task.wait
		
		expect(trapped).to be_truthy
	end
	
	it "should create transient task" do
		task = subject.async(transient: true) do
			# Trapped.
		end
		
		expect(task).to be_transient
	end
end
