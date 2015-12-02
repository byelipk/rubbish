require_relative './rubbish/version'
require_relative './rubbish/server'

module Rubbish
  ProtocolError = Class.new(RuntimeError)

  Error = Struct.new(:message) do
    def self.incorrect_args(cmd)
      new "wrong number of arguments for `#{cmd}` command"
    end
  end
end
