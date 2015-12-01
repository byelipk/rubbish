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
        handle_client(socket.accept)
      end
    end

    private

      def handle_client(client)
        # Now we can communicate to the client through
        # the client socket.
        client.write("+PONG\r\n")
      ensure
        client.close
      end

  end
end
