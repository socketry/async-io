# Async::IO::Endpoint

An endpoint is typically something you can connect to as a client, or bind to as a server. Sometimes the client and server endpoints need to be different, e.g. when dealing with TLS/SSL encryption where the client side needs a public key and the server side needs a private key.

## Shared Endpoints

Sometimes it's useful to bind or 

endpoint = Async::HTT::Endpoint.parse("https://localhost")

endpoint.

endpoint.wrap(SharedEndpoint.bound(endpoint))


