module Rubbish
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
