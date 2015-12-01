require_relative '../test_helper'

class SkeletonTest < Minitest::Test

  include AcceptanceHelper
  
  def test_server_responds_to_ping
    with_server do
      assert_equal "OK", client.ping
    end
  end
end
