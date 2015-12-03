require_relative '../test_helper'

module Acceptance
  class HashTest < Minitest::Test
    parallelize_me!

    include AcceptanceHelper

    def test_it_supports_hashes
      # This test is a little flaky. Sometimes it
      # will pass and other times it won't.
      with_server do
        client.hset('myhash', 'abc', '123')
        client.hset('myhash', 'def', '456')

        assert_equal ['123', '456'], client.hmget('myhash', 'abc', 'def')
      end
    end

  end
end
