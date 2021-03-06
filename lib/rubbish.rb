require 'rubbish/version'
require 'rubbish/server'

module Rubbish
  ProtocolError = Class.new(RuntimeError)

  Error = Struct.new(:message) do
    def self.incorrect_args(cmd)
      new "wrong number of arguments for `#{cmd}` command"
    end

    def self.unknown_command(cmd)
      new "unknown command `#{cmd}`"
    end

    def self.type_error
      new "wrong type for command"
    end
  end
end
