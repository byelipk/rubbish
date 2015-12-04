require 'socket'
require 'rubbish/config'
require 'rubbish/client'
require 'rubbish/state'

module Rubbish
  class Server
    attr_reader :port

    def initialize(port: Config::DEFAULT_PORT)
      @port   = port
      @state  = State.new
      @clock  = Clock.new

      # NOTE
      # Both ends of our shutdown pipe
      @r, @w  = IO.pipe
    end

    def shutdown
      w.close
    end

    def listen
      setup_listeners!

      readable = Array.new
      clients  = Hash.new
      server   = TCPServer.new(port)
      running  = true

      # NOTE
      # Both ends of our timer pipe
      _r, _w = IO.pipe

      readable << server
      readable << r
      readable << _r

      timer_thread = Thread.new do
        begin
          while running
            clock.sleep(0.1)

            # Write an arbitrary value to one
            # end of our timer pipe every clock cycle.
            _w.write(".") unless _w.closed?
          end
        rescue Errno::EPIPE
          # Do nothing...
        end
      end

      while running do
        ready_to_read, _ = IO.select(readable + clients.keys)

        # We will block until a client connects
        # to the `port` the server is listening on.
        ready_to_read.each do |socket|
          case socket
          when server then
            child_socket = socket.accept
            clients[child_socket] = Client.new(child_socket)
          when r  then running = false
          when _r then
            state.expire_keys!
          else
            begin
              clients[socket].process!(state)
            rescue EOFError
              clients.delete(socket)
              socket.close
            end
          end
        end
      end

    rescue Errno::EADDRINUSE
      retry
    ensure
      running = false

      (readable + clients.keys).each do |socket|
        socket.close
      end

      # Close both ends of our timer pipe
      _r.close unless _r.closed?
      _w.close unless _w.closed?

      timer_thread.join if timer_thread
    end

    private

      attr_reader :clock, :r, :w, :state

      def setup_listeners!
        Signal.trap("SIGINT") do
          print "\nTossing out the rubbish...\n"
          shutdown
        end
      end

  end
end
