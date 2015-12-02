require_relative '../test_helper'
require_relative '../../lib/rubbish/protocol'

class ProtocolTest < Minitest::Test
  def self.it_marshals(ruby, wire)
    test_name = ruby.to_s
    test_name.gsub!(/ /, '_')

    define_method "test_#{test_name}" do
      assert_equal wire, Rubbish::Protocol.marshal(ruby)
    end
  end

  it_marshals :ok,     "+OK\r\n"
  it_marshals nil,     "$-1\r\n"
  it_marshals "Hello", "$5\r\nHello\r\n"
end
