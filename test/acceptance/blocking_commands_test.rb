require_relative '../test_helper'

class BlockingCommandsTest < Minitest::Test

  include AcceptanceHelper

  def test_brpop_is_supported
    with_server do
      items = %w( a b )

      t1 = Thread.new do
        item = client.brpop('queue')
        assert_equal items.shift, item
      end

      t2 = Thread.new do
        item = client.brpop('queue')
        assert_equal items.shift, item
      end

      items.dup.each do |i|
        assert_equal 1, client.lpush('queue', i)
      end

      # Ensure that any exceptions raised on these threads
      # are re-raised in the main thread.
      t1.value
      t2.value
    end
  end

  # TODO
  # Keys that are not written to will just hang around.
  # We will need to clean them up.
  #
  # We need to keep track of the keys we're watching
  # in the client handler so we can explicitly clean
  # them out from the state on client disconnect.
  def test_it_handles_disconnecting_clients
    with_server do
      s = TCPSocket.new('localhost', TEST_PORT)
      s.write("*3\r\n$5\r\nbrpop\r\n$1\r\nq\r\n$1\r\no\r\n")
      s.close

      assert_equal 1, client.lpush('q', 'a')
      assert_equal 2, client.lpush('q', 'b')
    end
  end
end
