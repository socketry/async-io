# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'async/io/notification'

RSpec.describe Async::IO::Notification do
	include_context Async::RSpec::Reactor
	
	it "should wait for notification" do
		waiting_task = reactor.async do
			subject.wait
		end
		
		expect(waiting_task.status).to be :running
		
		signalling_task = reactor.async do
			subject.signal
		end
		
		signalling_task.wait
		waiting_task.wait
		
		expect(waiting_task).to be_complete
		
		subject.close
	end
end
