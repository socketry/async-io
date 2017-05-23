
require 'async/io'

RSpec.describe Async::IO::Generic do
	include_context Async::RSpec::Reactor
	
	let(:pipe) {IO.pipe}
	let(:input) {Async::IO::Generic.new(pipe.first)}
	let(:output) {Async::IO::Generic.new(pipe.last)}
	
	it "should send and receive data within the same reactor" do
		message = nil
		
		output_task = reactor.async do
			message = input.read(1024)
		end
		
		reactor.async do
			output.write("Hello World")
		end
		
		output_task.wait
		expect(message).to be == "Hello World"
		
		input.close
		output.close
	end
end
