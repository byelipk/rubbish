require 'stringio'
require 'forwardable'
require_relative './unmarshaler'
require_relative './protocol'
require_relative './transaction'

module Rubbish
  class Client

    extend Forwardable

    BYTES_TO_READ = 1024

    def_delegator :unmarshaler, :unmarshal

    def initialize(socket)
      @socket = socket
      @buffer = String.new

      reset_tx!
    end

    def reset_tx!
      @tx = Transaction.new
    end

    def process!(state)
      buffer << socket.read_nonblock(BYTES_TO_READ)

      # We will translate the current buffer into
      # as many commands as possible.
      cmds, processed = unmarshal(buffer)

      # Move the buffer forward by releasing
      # the commands that are about to be processed.
      @buffer = buffer[processed..-1]

      cmds.each do |cmd|
        response = response_for_client(cmd, state)

        unless response == :block
          respond_to_client!(response)
        end

        state.process_list_watches!
      end
    end

    def respond_to_client!(response)
      # Now we can communicate to the client through
      # the client socket.
      socket.write Rubbish::Protocol.marshal(response)
    end

    private

      attr_reader :socket, :buffer, :tx

      def unmarshaler
        Unmarshaler.new
      end

      def response_for_client(cmd, state)
        if tx.active?
          case cmd[0].downcase
          when "exec" then
            result = tx.buffer.map do |c|
              dispatch(state, c)
            end unless tx.dirty?

            reset_tx!
            result
          else
            tx.queue(cmd); :queued
          end
        else
          dispatch(state, cmd)
        end
      end

      def dispatch(state, cmd)
        case cmd[0].downcase
        when "ping"  then :pong
        when "echo"  then cmd[1]
        when "multi" then tx.start!; :ok
        when "watch" then
          current_tx = tx
          state.watch(cmd[1]) {
            tx.dirty! if current_tx == tx
          }
        when "brpop" then
          state.brpop(cmd[1], self)
        else state.apply_command(cmd)
        end
      end

  end
end
