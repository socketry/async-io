# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require 'async/io'
require 'async/clock'

require_relative 'generic_examples'

RSpec.describe Async::IO::Generic do
	include_context Async::RSpec::Reactor
	
	CONSOLE_METHODS = [:beep, :cooked, :cooked!, :cursor, :cursor=, :echo=, :echo?,:getch, :getpass, :goto, :iflush, :ioflush, :noecho, :oflush,:pressed?, :raw, :raw!, :winsize, :winsize=]
	# On TruffleRuby, IO#encode_with needs to be defined for YAML.dump as a public method, allow it
	ignore = [:encode_with, :check_winsize_changed, :clear_screen, :console_mode, :console_mode=, :cursor_down, :cursor_left, :cursor_right, :cursor_up, :erase_line, :erase_screen, :goto_column, :scroll_backward, :scroll_forward, :wait_priority]
	
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
				
				expect(duration).to be >= wait_duration
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
				
				expect(duration).to be >= wait_duration
				
				input.close
			end
			
			[reader].each(&:wait)
			
			output.close
		end
	end
end
