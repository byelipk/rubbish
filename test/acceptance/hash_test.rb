require_relative '../test_helper'

module Acceptance
  class HashTest < Minitest::Test
    parallelize_me!

    include AcceptanceHelper

    def test_it_supports_hashes
      with_server do
        assert_equal "OK",           client.hset('hash', 'abc', '123')
        assert_equal "OK",           client.hset('hash', 'def', '456')
        assert_equal "123",          client.hget('hash', 'abc')
        assert_equal ['123', '456'], client.hmget('hash', 'abc', 'def')
      end
    end

  end
end
