require 'socket'
require_relative './config'
require_relative './client'

module Rubbish
  class Server
    attr_reader :port

    def initialize(port: Config::DEFAULT_PORT)
      @port = port
    end

    def listen
      readable = Array.new
      clients  = Hash.new
      server   = TCPServer.new(port)

      readable << server

      loop do
        ready_to_read, _ = IO.select(readable + clients.keys)

        # We will block until a client connects
        # to the `port` the server is listening on.
        ready_to_read.each do |socket|
          case socket
          when server then
            child_socket = socket.accept
            clients[child_socket] = Client.new(child_socket)
          else
            clients[socket].process!
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
  end
end
