require 'timeout'
require 'minitest/autorun'
require 'pry'
require 'pry-byebug'
require 'redis'
require_relative '../lib/rubbish'

module AcceptanceHelper
  TEST_PORT = 6380

  def client
    Redis.new(host: 'localhost', port: TEST_PORT)
  end

  def with_server
    thread = Thread.new do
      server = Rubbish::Server.new(port: TEST_PORT)
      server.listen
    end

    wait_for_open_port TEST_PORT

    yield
  rescue TimeoutError
    sleep 0.01

    # Getting the value will here will return
    # any exception that was raised on the thread.
    thread.value unless thread.alive?

    # But we will re-raise the timeout error to ensure
    # the test always fails.
    raise
  ensure
    Thread.kill(thread) if thread
  end

  def wait_for_open_port(port)
    time = Time.now

    # If the port is in use we will take a short nap
    # to give time for the port to open up again.
    while !check_port(port) && 1 > Time.now - time
      sleep 0.01
    end

    # The port should be open now. But if it is not,
    # we will raise an exception.
    raise TimeoutError unless check_port(port)
  end

  def check_port(port)
    `nc -z localhost #{port}`
    $?.success?
  end
end
