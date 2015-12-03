require_relative '../test_helper'

module Acceptance
  class HashTest < Minitest::Test
    parallelize_me!

    include AcceptanceHelper

    def test_it_supports_hashes
      with_server do
        assert_equal "OK",   client.hset('myhash', 'abc', '123'), "Expected 123 to be OK"
        assert_equal "OK",   client.hset('myhash', 'def', '456'), "Expected 456 to be OK"

        assert_equal ['123', '456'], client.hmget('myhash', 'abc', 'def')
      end
    end

  end
end
