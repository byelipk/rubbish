module Rubbish
  class Client

    attr_reader :socket

    def initialize(socket)
      @socket = socket
    end

    def handle
      # We need to keep accepting data from
      # the client until the client disconnects.
      loop do
        cmd = fetch_command

        response = case cmd[0].downcase
        when "ping" then "+PONG\r\n"
        when "echo" then "$#{cmd[1].length}\r\n#{cmd[1]}\r\n"
        end

        # Now we can communicate to the client through
        # the client socket.
        socket.write(response)
      end
    ensure
      socket.close
    end

    private

      def fetch_command
        # We need to read from the client buffer
        # in order to process commands.
        header = socket.gets.to_s

        return unless header.start_with? "*"

        num_args = header[1..-1].to_i

        num_args.times.map do
          len = socket.gets[1..-1].to_i
          socket.read(len + 2).chomp
        end
      end
  end
end
