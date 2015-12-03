require_relative '../test_helper'

class ActiveExpiryTest < Minitest::Test

  include AcceptanceHelper

  def test_it_actively_expires_keys
    with_server do
      n = 10
      n.times do |i|
        client.set("expire:#{i}", i.to_s)
        client.set("keep:#{i}", i.to_s)

        client.pexpire("expire:#{i}", rand(600))
      end

      condition = ->() {
        client.keys("*").count {|x| x.start_with?("expire")} == 0
      }

      start_time = Time.now
      while !condition.call && Time.now < start_time + 2
        sleep 0.01
      end

      assert_equal true, condition.call
      assert_equal n,    client.keys("*").size
    end
  end
end
