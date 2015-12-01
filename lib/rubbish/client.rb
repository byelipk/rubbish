require 'stringio'

module Rubbish
  class Client

    BYTES_TO_READ = 1024

    attr_reader :socket
    attr_accessor :buffer

    def initialize(socket)
      @socket = socket
      @buffer = String.new
    end

    def process!
      buffer << socket.read_nonblock(BYTES_TO_READ)

      # We will translate the current buffer into
      # as many commands as possible.
      cmds, processed = unmarshal(buffer)

      @buffer = buffer[processed..-1]

      cmds.each do |cmd|
        response = case cmd[0].downcase
        when "ping" then "+PONG\r\n"
        when "echo" then "$#{cmd[1].length}\r\n#{cmd[1]}\r\n"
        end

        # Now we can communicate to the client through
        # the client socket.
        socket.write(response)
      end
    end



    private

      def unmarshal(data)
        io        = StringIO.new(data)
        result    = Array.new
        processed = 0

        begin
          loop do
            header = safe_readine(io)

            raise ProtocolError unless header.start_with?("*")

            n = header[1..-1].to_i

            result << n.times.map do
              raise ProtocolError unless io.readpartial(1) == "$"

              length = safe_readine(io).to_i
              safe_readpartial(io, length).tap do
                safe_readine(io)
              end
            end

            processed = io.pos
          end

        rescue ProtocolError
          processed = io.pos
        rescue EOFError
          # Incomplete command, ignore. Or there is
          # no more data to process.
        end

        [result, processed]
      end

      def safe_readine(io)
        io.readline("\r\n").tap do |line|
          raise EOFError unless line.end_with?("\r\n")
        end
      end

      def safe_readpartial(io, length)
        io.readpartial(length).tap do |data|
          raise EOFError unless data.length == length
        end
      end

  end
end
