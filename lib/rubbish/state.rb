require 'set'
require_relative './clock'

module Rubbish
  class State

    def initialize(store: Hash.new, clock: Clock.new)
      @store   = store
      @clock   = clock
      @expires = Hash.new
      @watches = Hash.new
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

    private

    attr_reader :store, :expires, :clock, :watches

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

  end

  class ZSet
    attr_reader :entries_to_score, :sorted_by_score

    def initialize
      @entries_to_score = Hash.new
      @sorted_by_score  = Array.new
    end

    def add(score, member)
      entries_to_score[member] = score
      elem  = [score, member]
      index = bsearch_index(sorted_by_score, elem)
      sorted_by_score.insert(index, elem)
    end

    def range(start, stop)
      sorted_by_score[start..stop].map {|x| x[1]}
    end

    def rank(member)
      score = entries_to_score[member]

      return unless score

      bsearch_index(sorted_by_score, [score, member])
    end

    def score(member)
      entries_to_score[member]
    end

    def bsearch_index(ary, x)
      return 0 if ary.empty?

      low  = 0
      high = ary.length - 1

      while high >= low
        idx  = low + (high - low) / 2
        comp = ary[idx] <=> x # 1, 0, -1

        if comp == 0
          return idx
        elsif comp > 0
          high = idx - 1
        else
          low = idx + 1
        end
      end

      idx + (comp < 0 ? 1 : 0)
    end
  end
end
