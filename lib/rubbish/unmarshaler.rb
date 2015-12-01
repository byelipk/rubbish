module Rubbish
  class Unmarshaler
    def unmarshal(data)
      io        = StringIO.new(data)
      result    = Array.new
      processed = 0

      begin
        loop do
          header = safe_readine(io)

          raise ProtocolError unless header.start_with?("*")

          n = header[1..-1].to_i

          result << n.times.map do
            raise ProtocolError unless io.readpartial(1) == "$"

            length = safe_readine(io).to_i
            safe_readpartial(io, length).tap do
              safe_readine(io)
            end
          end

          processed = io.pos
        end

      rescue ProtocolError
        processed = io.pos
      rescue EOFError
        # Incomplete command, ignore. Or there is
        # no more data to process.
      end

      [result, processed]
    end

    private

      def safe_readine(io)
        io.readline("\r\n").tap do |line|
          raise EOFError unless line.end_with?("\r\n")
        end
      end

      def safe_readpartial(io, length)
        io.readpartial(length).tap do |data|
          raise EOFError unless data.length == length
        end
      end
      
  end
end
