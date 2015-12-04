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
end
