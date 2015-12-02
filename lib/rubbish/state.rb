require_relative './store'

module Rubbish
  class State

    attr_reader :store

    def initialize(store: Store.new)
      @store = store
    end

    def set(key, value)
      store[key] = value
      :ok
    end

    def get(key)
      store[key]
    end
  end
end
