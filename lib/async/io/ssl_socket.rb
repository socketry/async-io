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

require_relative 'socket'

require 'openssl'

module Async
	module IO
		SSLError = OpenSSL::SSL::SSLError
		
		# Asynchronous TCP socket wrapper.
		class SSLSocket < Generic
			wraps ::OpenSSL::SSL::SSLSocket, :alpn_protocol, :cert, :cipher, :client_ca, :hostname=, :npn_protocol, :peer_cert, :peer_cert_chain, :pending, :post_connection_check, :session, :session=, :session_reused?, :ssl_version, :state
			
			wrap_blocking_method :accept, :accept_nonblock
			wrap_blocking_method :connect, :connect_nonblock
			
			def local_address
				@io.to_io.local_address
			end
			
			def remote_address
				@io.to_io.remote_address
			end
			
			# This method/implementation might change in the future, don't depend on it :)
			def self.connect_socket(socket, context)
				io = wrapped_klass.new(socket.to_io, context)
				
				# This ensures that when the internal IO is closed, it also closes the internal socket:
				io.sync_close = true
				
				return self.new(io, socket.reactor)
			end
		end
		
		class SSLServer
			extend Forwardable
			
			def initialize(server, context)
				@server = server
				@context = context
			end
			
			def_delegators :@server, :local_address, :setsockopt, :getsockopt
			
			attr :server
			attr :context
			
			include ServerSocket
			
			def listen(*args)
				@server.listen(*args)
			end
			
			def accept(task: Task.current)
				peer, address = @server.accept
				
				wrapper = SSLSocket.connect_socket(peer, @context)
				
				if block_given?
					task.async do
						task.annotate "accepting secure connection #{address}"
						
						begin
							wrapper.accept
							
							yield wrapper, address
						rescue SSLError
							Async.logger.error($!.class) {$!}
						ensure
							wrapper.close
						end
					end
				else
					return wrapper, address
				end
			end
		end
	end
end
