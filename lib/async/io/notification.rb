# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'generic'

module Async
	module IO
		# A cross-reactor/process notification pipe.
		class Notification
			def initialize
				pipe = ::IO.pipe
				
				# We could call wait and signal from different reactors/threads/processes, so we don't create wrappers here, because they are not thread safe by design.
				@input = pipe.first
				@output = pipe.last
			end
			
			def close
				@input.close
				@output.close
			end
			
			# Wait for signal to be called.
			# @return [Object]
			def wait
				wrapper = Async::IO::Generic.new(@input)
				wrapper.read(1)
			ensure
				# Remove the wrapper from the reactor.
				wrapper.reactor = nil
			end
			
			# Signal to a given task that it should resume operations.
			# @return [void]
			def signal
				wrapper = Async::IO::Generic.new(@output)
				wrapper.write(".")
			ensure
				wrapper.reactor = nil
			end
		end
	end
end
