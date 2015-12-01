module Rubbish
  class Client

    attr_reader :socket

    def initialize(socket)
      @socket = socket
    end

    def handle
      cmd = read_buffer

      return unless cmd

      response = case cmd[0].downcase
      when "ping" then "+PONG\r\n"
      when "echo" then "$#{cmd[1].length}\r\n#{cmd[1]}\r\n"
      end

      # Now we can communicate to the client through
      # the client socket.
      socket.write(response)
    end

    private

      def read_buffer
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
