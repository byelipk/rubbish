require_relative '../test_helper'

class SkeletonTest < Minitest::Test

  parallelize_me!

  include AcceptanceHelper

  def test_server_responds_to_ping
    with_server do
      assert_equal "PONG", client.ping
    end
  end

  def test_it_responds_to_echo
    with_server do
      assert_equal "hello", client.echo("hello")
    end
  end
end
