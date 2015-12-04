require 'stringio'
require 'forwardable'
require_relative './unmarshaler'
require_relative './protocol'

module Rubbish
  class Client

    extend Forwardable

    BYTES_TO_READ = 1024

    def_delegator :unmarshaler, :unmarshal

    def initialize(socket)
      @socket = socket
      @buffer = String.new
    end

    def process!(state)
      buffer << socket.read_nonblock(BYTES_TO_READ)

      # We will translate the current buffer into
      # as many commands as possible.
      cmds, processed = unmarshal(buffer)

      @buffer = buffer[processed..-1]

      cmds.each do |cmd|
        response = case cmd[0].downcase
        when "ping"  then :pong
        when "echo"  then cmd[1]
        else state.apply_command(cmd)
        end

        # Now we can communicate to the client through
        # the client socket.
        socket.write Rubbish::Protocol.marshal(response)
      end
    end

    private

      attr_reader :socket, :buffer

      def unmarshaler
        Unmarshaler.new
      end

  end
end
