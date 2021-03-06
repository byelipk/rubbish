module Rubbish
  class Protocol
    def self.marshal(ruby)
      case ruby
      when Symbol  then "+#{ruby.to_s.upcase}\r\n"
      when String  then "$#{ruby.length}\r\n#{ruby}\r\n"
      when Array   then "*#{ruby.length}\r\n#{ruby.map {|x| marshal(x)}.join}"
      when Integer then ":#{ruby}\r\n"
      when nil     then "$-1\r\n"
      when Error   then "-ERR #{ruby.message}\r\n"
      else
        raise "-ERR Don't know how to marshal: #{ruby}\r\n"
      end
    end
  end
end
