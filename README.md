# Async::IO

Async::IO provides builds on [async](https://github.com/socketry/async) and provides asynchronous wrappers for `IO`, `Socket`, and related classes.

[![Development Status](https://github.com/socketry/async-io/workflows/Development/badge.svg)](https://github.com/socketry/async-io/actions?workflow=Development)

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'async-io'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install async-io

## Usage

Basic echo server (from `spec/async/io/echo_spec.rb`):

``` ruby
require 'async/io'

def echo_server(endpoint)
  Async do |task|
    # This is a synchronous block within the current task:
    endpoint.accept do |client|
      # This is an asynchronous block within the current reactor:
      data = client.read

      # This produces out-of-order responses.
      task.sleep(rand * 0.01)

      client.write(data.reverse)
      client.close_write
    end
  end
end

def echo_client(endpoint, data)
  Async do |task|
    endpoint.connect do |peer|
      peer.write(data)
      peer.close_write

      message = peer.read

      puts "Sent #{data}, got response: #{message}"
    end
  end
end

Async do
  endpoint = Async::IO::Endpoint.tcp('0.0.0.0', 9000)

  server = echo_server(endpoint)

  5.times.map do |i|
    echo_client(endpoint, "Hello World #{i}")
  end.each(&:wait)

  server.stop
end
```

### Timeouts

Timeouts add a temporal limit to the execution of your code. If the IO doesn't respond in time, it will fail. Timeouts are high level concerns and you generally shouldn't use them except at the very highest level of your program.

``` ruby
message = task.with_timeout(5) do
  begin
    peer.read
  rescue Async::TimeoutError
    nil # The timeout was triggered.
  end
end
```

Any `yield` operation can cause a timeout to trigger. Non-`async` functions might not timeout because they are outside the scope of `async`.

#### Wrapper Timeouts

Asynchronous operations may block forever. You can assign a per-wrapper operation timeout duration. All asynchronous operations will be bounded by this timeout.

``` ruby
peer.timeout = 1
peer.read # If this takes more than 1 second, Async::TimeoutError will be raised.
```

The benefit of this approach is that it applies to all operations. Typically, this would be configured by the user, and set to something pretty high, e.g. 120 seconds.

### Reading Characters

This example shows how to read one character at a time as the user presses it on the keyboard, and echos it back out as uppercase:

``` ruby
require 'async'
require 'async/io/stream'
require 'io/console'

$stdin.raw!
$stdin.echo = false

Async do |task|
  stdin = Async::IO::Stream.new(
    Async::IO::Generic.new($stdin)
  )

  while character = stdin.read(1)
    $stdout.write character.upcase
  end
end
```

### Deferred Buffering

`Async::IO::Stream.new(..., deferred:true)` creates a deferred stream which increases latency slightly, but reduces the number of total packets sent. It does this by combining all calls `Stream#flush` within a single iteration of the reactor. This is typically more useful on the client side, but can also be useful on the server side when individual packets have high latency. It should be preferable to send one 100 byte packet than 10x 10 byte packets.

Servers typically only deal with one request per iteartion of the reactor so it's less useful. Clients which make multiple requests can benefit significantly e.g. HTTP/2 clients can merge many requests into a single packet. Because HTTP/2 recommends disabling Nagle's algorithm, this is often beneficial.

## Contributing

1.  Fork it
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create new Pull Request

## See Also

  - [async](https://github.com/socketry/async) — Asynchronous event-driven reactor.
  - [async-process](https://github.com/socketry/async-process) — Asynchronous process spawning/waiting.
  - [async-websocket](https://github.com/socketry/async-websocket) — Asynchronous client and server websockets.
  - [async-dns](https://github.com/socketry/async-dns) — Asynchronous DNS resolver and server.
  - [async-rspec](https://github.com/socketry/async-rspec) — Shared contexts for running async specs.
  - [rubydns](https://github.com/ioquatix/rubydns) — A easy to use Ruby DNS server.

## License

Released under the MIT license.

Copyright, 2017, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
