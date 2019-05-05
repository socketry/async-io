# wat.rb
require 'async'
require_relative '../../lib/async/io'
require 'digest/sha1'
require 'securerandom'

Async.run do |task|
	r, w = IO.pipe.map { |io| Async::IO.try_convert(io) }

	task.async do |subtask|
		s = Digest::SHA1.new
		l = 0
		100.times do
			bytes = SecureRandom.bytes(4000)
			s << bytes
			w << bytes
			l += bytes.bytesize
		end
		w.close
		p [:write, l, s.hexdigest]
	end
	
	task.async do |subtask|
		s = Digest::SHA1.new
		l = 0
		while b = r.read(4096)
			s << b
			l += b.bytesize
		end
		p [:read, l, s.hexdigest]
	end
end
