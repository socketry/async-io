# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/io'
require 'async/clock'

require_relative 'generic_examples'

RSpec.describe Async::IO::Generic do
	include_context Async::RSpec::Reactor
	
	CONSOLE_METHODS = [:beep, :cooked, :cooked!, :cursor, :cursor=, :echo=, :echo?,:getch, :getpass, :goto, :iflush, :ioflush, :noecho, :oflush,:pressed?, :raw, :raw!, :winsize, :winsize=]
	# On TruffleRuby, IO#encode_with needs to be defined for YAML.dump as a public method, allow it
	ignore = [:encode_with]
	
	it_should_behave_like Async::IO::Generic, [
		:bytes, :chars, :codepoints, :each, :each_byte, :each_char, :each_codepoint, :each_line, :getbyte, :getc, :gets, :lineno, :lineno=, :lines, :print, :printf, :putc, :puts, :readbyte, :readchar, :readline, :readlines, :ungetbyte, :ungetc
	] + CONSOLE_METHODS + ignore
	
	let(:message) {"Hello World!"}
	
	let(:pipe) {IO.pipe}
	let(:input) {Async::IO::Generic.new(pipe.first)}
	let(:output) {Async::IO::Generic.new(pipe.last)}
	
	it "should send and receive data within the same reactor" do
		received = nil
		
		output_task = reactor.async do
			received = input.read(1024)
			input.close
		end
		
		reactor.async do
			output.write(message)
			output.close
		end
		
		output_task.wait
		expect(received).to be == message
	end
	
	describe '#wait' do
		let(:wait_duration) {0.1}
		
		it "can wait for :read and :write" do
			reader = reactor.async do |task|
				duration = Async::Clock.measure do
					input.wait(1, :read)
				end
				
				expect(duration).to be_within(100).percent_of(wait_duration)
				expect(input.read(1024)).to be == message
				
				input.close
			end
			
			writer = reactor.async do |task|
				duration = Async::Clock.measure do
					output.wait(1, :write)
				end
				
				task.sleep(wait_duration)
				
				output.write(message)
				output.close
			end
			
			[reader, writer].each(&:wait)
		end
		
		it "can return nil when timeout is exceeded" do
			reader = reactor.async do |task|
				duration = Async::Clock.measure do
					expect(input.wait(wait_duration, :read)).to be_nil
				end
				
				expect(duration).to be_within(100).percent_of(wait_duration)
				
				input.close
			end
			
			[reader].each(&:wait)
			
			output.close
		end
	end
end
