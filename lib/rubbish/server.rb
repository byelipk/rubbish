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
        Thread.start(socket.accept) do |client|
          # We will block until a client connects
          # to the `port` the server is listening on.
          handle_client(client)
        end
      end

    rescue Errno::EADDRINUSE
      retry
    ensure
      socket.close if socket
    end

    private

      def handle_client(client)
        # We need to keep accepting data from
        # the client until the client disconnects.
        loop do
          # We need to read from the client buffer
          # in order to process commands.
          header = client.gets.to_s

          return unless header.start_with? "*"

          num_args = header[1..-1].to_i

          cmd = num_args.times.map do
            len = client.gets[1..-1].to_i
            client.read(len + 2).chomp
          end

          response = case cmd[0].downcase
          when "ping" then "+PONG\r\n"
          when "echo" then "$#{cmd[1].length}\r\n#{cmd[1]}\r\n"
          end

          # Now we can communicate to the client through
          # the client socket.
          client.write(response)
        end
      ensure
        client.close
      end

  end
end
