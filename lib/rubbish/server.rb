require 'socket'

module Rubbish
  class Server
    attr_reader :port

    def initialize(port: Config::DEFAULT_PORT)
      @port = port
    end

    def listen
      socket = TCPServer.new(port)

      loop do
        # We will block until a client connects
        # to the `port` the server is listening on.
        Thread.start(socket.accept) do |client|
          Client.new(client).handle
        end
      end

    rescue Errno::EADDRINUSE
      retry
    ensure
      socket.close if socket
    end
  end
end
