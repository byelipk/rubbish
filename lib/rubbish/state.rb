require 'set'
require_relative './clock'
require_relative './zset'

module Rubbish
  class State

    def initialize(store: Hash.new, clock: Clock.new)
      @store        = store
      @clock        = clock
      @expires      = Hash.new
      @watches      = Hash.new
      @list_watches = Hash.new
      @ready_keys   = Array.new
    end

    def self.valid_commands
      @valid_commands ||= Set.new(
        public_instance_methods(false).map(&:to_s) - readonly_commands
      )
    end

    def self.readonly_commands
      %w( apply_command watch )
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

    def process_list_watches!
      ready_keys.each do |key|
        list    = get(key)
        watches = list_watches.fetch(key, [])

        while list.any? && watches.any?
          op, client = *watches.shift
          client.respond!(op.call)
        end
      end

      ready_keys.clear
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

        touch!(key)
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
      touch!(key)
      expires.delete(key)
      store.delete(key)
    end

    def hset(hash, key, value)
      store[hash] ||= Hash.new
      store[hash][key] = value

      touch!(key)
      :ok
    end

    def hget(hash, key)
      value = get(hash)
      value[key] if value
    end

    def hmget(hash, *keys)
      existing = get(hash) || Hash.new

      if existing.is_a?(Hash)
        existing.values_at(*keys)
      else
        Error.type_error
      end
    end

    def hincrby(hash, key, amount)
      value = get(hash)

      if value
        existing = value[key]
        value[key] = existing.to_i + amount.to_i
        touch!(key)

        value[key]
      end
    end

    def expire(key, duration)
      pexpire(key, (duration.to_i * 1000))
    end

    def pexpire(key, duration)
      if get(key)
        expires[key] = clock.now + (duration.to_i / 1000)
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

    def keys(pattern)
      if pattern == "*"
        store.keys
      else
        raise NotImplementedError,
          "keys only accepts a catchall `*`"
      end
    end

    def expire_keys!(n: 100, threshold: 0.25, rng: Random.new)
      begin
        expired = expires.keys.sample(n, random: rng).count do |key|
          # NOTE
          # Here we can leverage our passive
          # key expiry system already in place.
          get(key)
        end
      end while expired > n * threshold
    end

    def zadd(key, score, member)
      score = score.to_f

      value = get(key) || store[key] = ZSet.new

      value.add(score, member)

      touch!(key)

      1
    end

    def zrange(key, start, stop)
      value = get(key)
      if value
        value.range(start.to_i, stop.to_i)
      else
        []
      end
    end

    def zrank(key, member)
      value = get(key)
      if value
        value.rank(member)
      end
    end

    def zscore(key, member)
      value = get(key)
      if value
        value.score(member)
      end
    end

    def watch(key, &blk)
      watches[key] ||= Array.new
      watches[key] << blk if blk
      :ok
    end

    def lpush(key, value)
      list = safe_list(key)

      if list_watches.fetch(key, []).any?
        ready_keys << key
      end

      touch!(key)
      list.unshift(value)
      list.length
    end

    def rpush(key, value)
      list = safe_list(key)

      touch!(key)
      list.push(value)
      list.length
    end

    def llen(key)
      list = get(key) || Array.new
      list.length
    end

    def rpop(key)
      list = safe_list(key)

      touch!(key)
      list.pop
    end

    def lpop(key)
      list = safe_list(key)

      touch!(key)
      list.shift
    end

    def lrange(key, start, stop)
      list = safe_list(key)

      list[start.to_i..stop.to_i]
    end

    def brpop(key, client)
      list = safe_list(key)

      action = ->{ rpop(key) }

      if list.empty?
        list_watches[key] ||= []
        list_watches[key] << [action, client]
        :block
      else
        action.call
      end
    end

    private

    attr_reader :store,
                :expires,
                :clock,
                :watches,
                :list_watches,
                :ready_keys

    def exists?(key)
      store.has_key?(key)
    end

    # NOTE
    # If a key is never updated, we never actually
    # clear out any callbacks even though the
    # transaction may have finished.
    def touch!(key)
      ws = watches.delete(key) || []
      ws.each(&:call)
    end

    def safe_list(key)
      list = get(key)
      list ||= store[key] = Array.new
      list
    end

  end
end
