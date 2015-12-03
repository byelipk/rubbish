require 'set'
require_relative './store'
require_relative './clock'

module Rubbish
  class State

    def initialize(store: Store.new, clock: Clock.new)
      @store   = store
      @clock   = clock
      @expires = Hash.new
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
      expiry = expires[key]
      del(key) if expiry && expiry <= clock.now

      store[key]
    end

    def del(key)
      expires.delete(key)
      store.delete(key)
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
      existing = store.fetch(hash, {})
      if existing.is_a?(Hash)
        existing.values_at(*keys)
      else
        Error.type_error
      end
    end

    def hincrby(hash, key, amount)
      existing = hget(hash, key)
      store[hash][key] = existing.to_i + amount.to_i
    end

    def expire(key, duration)
      if get(key)
        expires[key] = clock.now + duration.to_i
        1
      else
        0
      end
    end

    def exists(key)
      if store[key]
        1
      else
        0
      end
    end

    private

    attr_reader :store, :expires, :clock

    def exists?(key)
      store.has_key?(key)
    end

  end
end
