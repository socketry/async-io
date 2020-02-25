#!/usr/bin/env ruby

require 'async'
require 'async/io/notification'

def defer(*args, &block)
	Async do
		notification = Async::IO::Notification.new
		
		thread = Thread.new(*args) do
			yield
		ensure
			notification.signal
		end
		
		notification.wait
		thread.join
	end
end

Async do
	10.times do
		defer do
			puts "I'm going to sleep"
			sleep 1
			puts "I'm going to wake up"
		end
	end
end
