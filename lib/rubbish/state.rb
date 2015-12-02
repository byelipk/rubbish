require 'set'
require_relative './store'

module Rubbish
  class State

    def initialize(store: Store.new)
      @store = store
    end

    def self.valid_commands
      @valid_commands ||= Set.new(
        public_instance_methods(false).map(&:to_s) - readonly_commands
      )
    end

    def self.readonly_commands
      %w( apply_command )
    end

    def self.valid_command?(cmd)
      valid_commands.include?(cmd[0])
    end

    def apply_command(cmd)
      unless State.valid_command?(cmd)
        return Error.unknown_command(cmd)
      end

      public_send(*cmd)
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

    def hset(hash, key, value)
      store[hash] ||= Hash.new
      store[hash][key] = value

      :ok
    end

    def hget(hash, key)
      store[hash][key]
    end

    def hmget(hash, *keys)
      store[hash].values_at(*keys)
    end

    def hincrby(hash, key, amount)
      existing = hget(hash, key)
      store[hash][key] = existing.to_i + amount.to_i
    end

    private

    attr_reader :store

    def exists?(key)
      store.has_key?(key)
    end

  end
end
