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
end
