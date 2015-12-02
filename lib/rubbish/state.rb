require_relative './store'

module Rubbish
  class State

    attr_reader :store

    def initialize(store: Store.new)
      @store = store
    end

    def set(*args)
      key, value, modifier = *args

      unless key && value
        return Error.incorrect_args('set')
      end

      nx = modifier == "NX"
      xx = modifier == "XX"

      if (!nx && !xx)          ||
         (nx && !exists?(key)) ||
         (xx && exists?(key))

        store[key] = value
        :ok
      end
    end

    def get(key)
      store[key]
    end

    private

      def exists?(key)
        store.has_key?(key)
      end
  end
end
