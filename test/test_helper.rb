require 'timeout'
require 'minitest/autorun'
require 'pry'
require 'pry-byebug'
require 'redis'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'rubbish'

module AcceptanceHelper
  TEST_PORT = 6380

  def client
    Redis.new(host: 'localhost', port: TEST_PORT)
  end

  def with_server
    server = nil
    thread = Thread.new do
      server = Rubbish::Server.new(port: TEST_PORT)
      server.listen
    end

    wait_for_open_port TEST_PORT

    yield

  # rescue Redis::ConnectionError, Redis::CannotConnectError
    # NOTE
    # This is to keep our tests passing if they
    # keep smashing into each other during test
    # runs.
    # retry
  rescue TimeoutError
    sleep 0.01

    # Getting the value will here will return
    # any exception that was raised on the thread.
    thread.value unless thread.alive?

    # But we will re-raise the timeout error to ensure
    # the test always fails.
    raise
  ensure
    server.shutdown if server
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
