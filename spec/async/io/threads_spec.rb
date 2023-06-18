# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'async/io/threads'

RSpec.describe Async::IO::Threads do
	include_context Async::RSpec::Reactor
	
	describe '#async' do
		it "can schedule work on a different thread" do
			thread = subject.async do
				Thread.current
			end.wait
			
			expect(thread).to be_kind_of Thread
			expect(thread).to_not be Thread.current
		end
		
		it "can kill thread when stopping task" do
			sleeping = Async::IO::Notification.new
			
			thread = nil
			
			task = subject.async do
				thread = Thread.current
				sleeping.signal
				sleep
			end
			
			sleeping.wait
			
			task.stop
			10.times do
				pp thread
				sleep(0.1)
				break unless thread.status
			end
			
			expect(thread.status).to be_nil
		ensure
			sleeping.close
		end
	end
end
