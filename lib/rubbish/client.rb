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
      @tx_buf = nil
    end

    def in_tx?
      @tx_buf
    end

    def process!(state)
      buffer << socket.read_nonblock(BYTES_TO_READ)

      # We will translate the current buffer into
      # as many commands as possible.
      cmds, processed = unmarshal(buffer)

      @buffer = buffer[processed..-1]

      cmds.each do |cmd|
        response = if in_tx?
          case cmd[0].downcase
          when "exec" then
            result  = @tx_buf.map {|c| dispatch(state, c)}
            @tx_buf = nil
            result
          else
            @tx_buf << cmd; :queued
          end
        else
          dispatch(state, cmd)
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

      def dispatch(state, cmd)
        case cmd[0].downcase
        when "ping"  then :pong
        when "echo"  then cmd[1]
        when "multi" then @tx_buf = []; :ok
        else state.apply_command(cmd)
        end
      end

  end
end
