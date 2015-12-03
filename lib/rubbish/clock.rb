class Clock
  def now
    Time.now.to_f
  end

  def sleep(duration)
    ::Kernel.sleep(duration)
  end
end
