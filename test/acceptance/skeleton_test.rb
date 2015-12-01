require_relative '../test_helper'

class SkeletonTest < Minitest::Test

  parallelize_me!

  include AcceptanceHelper

  def test_server_responds_to_ping
    with_server do
      c = client
      c.without_reconnect do
        assert_equal "PONG", c.ping
        assert_equal "PONG", c.ping
        assert_equal "PONG", c.ping
      end
    end
  end

  def test_it_responds_to_echo
    with_server do
      assert_equal "hello", client.echo("hello")
    end
  end

  def test_it_supports_multiple_client_connections
    with_server do
      assert_equal "hello", client.echo("hello")
      assert_equal "hello", client.echo("hello")
      assert_equal "hello", client.echo("hello")
    end
  end
end
