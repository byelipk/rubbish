require_relative '../test_helper'
require_relative '../../lib/rubbish/state'

class FakeClock
  def initialize
    @t = 0
  end

  def now
    @t
  end

  def sleep(duration)
    @t += duration
  end
end

class StateTest < Minitest::Test

  def setup
    @clock = FakeClock.new
    @state = Rubbish::State.new(clock: @clock)
  end

  def test_set_cmd_sets_value
    assert_equal :ok,   @state.set('abc', '123')
    assert_equal '123', @state.get('abc')
  end

  def test_set_does_not_overwrite_existing_value_with_NX
    assert_equal :ok,   @state.set('abc', '123', 'NX')
    assert_equal nil,   @state.set('abc', '456', 'NX')
    assert_equal '123', @state.get('abc')
  end

  def test_set_value_if_it_already_exists_with_XX
    assert_equal nil,   @state.set('abc', '123', 'XX')
    assert_equal :ok,   @state.set('abc', '123')
    assert_equal :ok,   @state.set('abc', '456', 'XX')
    assert_equal '456', @state.get('abc')
  end

  def test_set_returns_error_for_wrong_number_of_arguments
    assert_equal Rubbish::Error.incorrect_args('set'),
      @state.set('abc')
  end

  def test_hset_sets_value
    assert_equal :ok,   @state.hset('myhash', 'abc', '123')
    assert_equal :ok,   @state.hset('otherh', 'abc', '123')
    assert_equal '123', @state.hget('myhash', 'abc')
  end

  def test_hmget_returns_multiple_value
    assert_equal :ok,   @state.hset('myhash', 'abc', '123')
    assert_equal :ok,   @state.hset('myhash', 'def', '456')
    assert_equal ['123', '456'],   @state.hmget('myhash', 'abc', 'def')
  end

  def test_hmget_returns_error_when_not_hash_value
    @state.set('myhash', 'bogus')
    assert_equal Rubbish::Error.type_error,
      @state.hmget('myhash', 'key')
  end

  def test_hmget_returns_nils_when_empty
    assert_equal [nil], @state.hmget('myhash', 'key')
  end

  def test_hincrby_increments_counter_stored_in_hash
    @state.hset('myhash', 'abc', '1')
    assert_equal 3, @state.hincrby('myhash', 'abc', '2')
  end

  def test_passive_expire_on_a_key
    @state.set('abc', '123')
    @state.expire('abc', '1')
    @clock.sleep 0.9
    assert_equal '123', @state.get('abc')
    @clock.sleep 0.1
    assert_nil @state.get('abc')
  end
end
