require 'socket'
require_relative './config'
require_relative './client'
require_relative './store'

module Rubbish
  class Server
    attr_reader :port, :shutdown_pipe, :store

    def initialize(port: Config::DEFAULT_PORT)
      @port          = port
      @shutdown_pipe = IO.pipe
      @store         = Store.new
    end

    def shutdown
      shutdown_pipe.last.close
    end

    def listen
      setup_listeners!

      readable = Array.new
      clients  = Hash.new
      server   = TCPServer.new(port)
      running  = true

      readable << server
      readable << shutdown_pipe.first

      while running do
        ready_to_read, _ = IO.select(readable + clients.keys)

        # We will block until a client connects
        # to the `port` the server is listening on.
        ready_to_read.each do |socket|
          case socket
          when server then
            child_socket = socket.accept
            clients[child_socket] = Client.new(child_socket)
          when shutdown_pipe.first then
            running = false
          else
            begin
              clients[socket].process!(store)
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
      (readable + clients.keys).each do |socket|
        socket.close
      end
    end

    private

      def setup_listeners!
        Signal.trap("SIGINT") do
          print "\nTossing out the rubbish...\n"
          shutdown
        end
      end

  end
end
