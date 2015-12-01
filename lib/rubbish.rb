require_relative './rubbish/version'
require_relative './rubbish/server'

module Rubbish
  ProtocolError = Class.new(RuntimeError)
end
