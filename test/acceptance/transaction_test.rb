require_relative '../test_helper'

class TransactionTest < Minitest::Test

  include AcceptanceHelper

  def test_it_handles_transactions
    with_server do
      c = client

      result = c.multi do
        c.set('abc', '123')
        c.get('abc')
      end

      assert_equal result, %w( OK 123 )

      begin
        c.multi do
          c.set('abc', '456')
          raise
        end
      rescue
      end

      assert_equal '123', c.get('abc')

    end
  end

  def test_it_supports_watch
    with_server do
      c1 = client
      c2 = client

      c1.set('hello', 'world')

      c1.watch('hello')

      c2.set('hello', 'goodbye')

      c1.multi do
        c1.set('hello', 'world and beyond')
      end

      # Previous transaction should not have executed

      assert_equal 'goodbye', c1.get('hello')

      # A retry should work
      c1.watch('hello')

      c1.multi do
        c1.set('hello', 'multi')
      end

      assert_equal 'multi', c1.get('hello')
    end
  end
end
