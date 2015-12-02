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

    def process!(store)
      buffer << socket.read_nonblock(BYTES_TO_READ)

      # We will translate the current buffer into
      # as many commands as possible.
      cmds, processed = unmarshal(buffer)

      @buffer = buffer[processed..-1]

      cmds.each do |cmd|
        response = case cmd[0].downcase
        when "ping" then "+PONG\r\n"
        when "echo" then "$#{cmd[1].length}\r\n#{cmd[1]}\r\n"
        when "get"  then
          value = store[cmd[1]]
          if value
            "$#{value.length}\r\n#{value}\r\n"
          else
            "$-1\r\n"
          end
        when "set"  then
          store[cmd[1]] = cmd[2]
          "+OK\r\n"
        end

        # Now we can communicate to the client through
        # the client socket.
        socket.write(response)
      end
    end

    private

      def unmarshaler
        Unmarshaler.new
      end

  end
end
