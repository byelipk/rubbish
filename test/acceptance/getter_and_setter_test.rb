require_relative '../test_helper'

class GetterAndSetterTest < Minitest::Test

  parallelize_me!

  include AcceptanceHelper

  def test_it_gets_and_sets_values
    with_server do
      assert_equal nil,   client.get('abc')
      assert_equal "OK",  client.set('abc', '123')
      assert_equal "123", client.get('abc')
    end
  end

end
