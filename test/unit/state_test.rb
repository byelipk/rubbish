require_relative '../test_helper'
require_relative '../../lib/rubbish/state'

class StateTest < Minitest::Test

  def setup
    @state = Rubbish::State.new
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
    assert_equal '123', @state.hget('myhash', 'abc')
  end
end
