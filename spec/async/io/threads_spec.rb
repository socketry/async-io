# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
