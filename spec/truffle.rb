
require 'socket'

class IO
	def write_nonblock(data, exception: true)
		ensure_open_and_writable

		data = String data
		return 0 if data.empty?

		@ibuffer.unseek!(self) unless @sync

		self.nonblock = true

		begin
			Truffle::POSIX.write_string_nonblock(self, data)
		rescue Errno::EAGAIN
			if exception
				raise EAGAINWaitWritable
			else
				return :wait_writable
			end
		end
	end
end

class IO::BidirectionalPipe
	def write_nonblock(*args, **options)
		@write.write_nonblock(*args, **options)
	end
end

class Socket
	def connect_nonblock(sockaddr, exception: true)
		fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)

		if sockaddr.is_a?(Addrinfo)
			sockaddr = sockaddr.to_sockaddr
		end

		status = Truffle::Socket::Foreign.connect(descriptor, sockaddr)

		# There should be a better way to do this than raising an exception!?
		if Errno.errno == Errno::EISCONN::Errno
			raise Errno::EISCONN
		end

		if status < 0
			if exception
				Truffle::Socket::Error.write_nonblock('connect(2)')
			else
				:wait_writable
			end
		else
			0
		end
	end
end
