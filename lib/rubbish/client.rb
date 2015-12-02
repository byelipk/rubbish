require 'stringio'
require 'forwardable'
require_relative './unmarshaler'
require_relative './protocol'

module Rubbish
  class Client

    extend Forwardable

    BYTES_TO_READ = 1024

    attr_reader :socket
    attr_accessor :buffer

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
        when "ping" then :pong
        when "echo" then cmd[1]
        when "get"  then state.get(cmd[1])
        when "set"  then state.set(cmd[1], cmd[2])
        end

        # Now we can communicate to the client through
        # the client socket.
        socket.write Rubbish::Protocol.marshal(response)
      end
    end

    private

      def unmarshaler
        Unmarshaler.new
      end

  end
end
