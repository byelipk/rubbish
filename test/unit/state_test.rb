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

  def self.shared_expiry_examples(description, setter, getter)
    key = 'abc'
    description.gsub!(/ /, '_')

    define_method "test_#{description}" do
      setter.call(@state, key)
      @state.expire(key, '1')

      @clock.sleep 0.9
      getter.call(@state, key)
      assert_equal 1, @state.exists(key)

      @clock.sleep 0.1
      getter.call(@state, key)
      assert_equal 0, @state.exists(key)
    end
  end

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

  def test_exists_returns_number_of_keys
    assert_equal 0, @state.exists('abc')
    @state.set('abc', '123')
    assert_equal 1, @state.exists('abc')
  end

  shared_expiry_examples "get and set have passive expiry on a key",
    ->(s,k) {s.set(k, '123')},
    ->(s,k) {s.get(k)}

  shared_expiry_examples "hget has passive expiry",
    ->(s,k) {s.hset(k, 'abc', '123')},
    ->(s,k) {s.hget(k, 'abc')}

  shared_expiry_examples "hmget has passive expiry",
    ->(s,k) {s.hset(k, 'abc', '123')},
    ->(s,k) {s.hmget(k, 'abc')}

  shared_expiry_examples "hincrby has passive expiry",
    ->(s,k) {s.hset(k, 'abc', '123')},
    ->(s,k) {s.hincrby(k, 'abc', '1')}


  def test_keys_returns_all_keys_in_database
    @state.set('abc', '123')
    @state.set('def', '456')

    assert_equal @state.keys("*"), %w( abc def )
  end

end
