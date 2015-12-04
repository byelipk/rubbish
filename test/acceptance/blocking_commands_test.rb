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
end
