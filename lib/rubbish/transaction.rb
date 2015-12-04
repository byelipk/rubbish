module Rubbish
  class Transaction

    attr_reader :buffer
    
    def initialize
      @active = false
      @buffer = Array.new
    end

    def active?
      @active
    end

    def start!
      raise if active?
      @active = true
    end

    def queue(cmd)
      raise unless active?
      @buffer << cmd
    end

  end
end
