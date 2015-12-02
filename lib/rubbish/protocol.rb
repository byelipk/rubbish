module Rubbish
  class Protocol
    def self.marshal(ruby)
      case ruby
      when Symbol then "+#{ruby.to_s.upcase}\r\n"
      when String then "$#{ruby.length}\r\n#{ruby}\r\n"
      when nil    then "$-1\r\n"
      else
        raise "-ERR Don't know how to marshal: #{ruby}\r\n"
      end
    end
  end
end
