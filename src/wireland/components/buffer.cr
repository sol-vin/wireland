class WC::Buffer < WC
  def self.active?
    true
  end

  def self.allow_adjacent?
    true
  end

  def self.output_whitelist
    super.reject { |c| c == self }
  end

  def on_high
    state_queue << true
  end

  def on_low
    state_queue << false
  end

  def on_tick
    if state_queue.shift
      parent.active_pulse(id, connects.dup)
    end
  end

  getter state_queue = [] of Bool

  def initialize(@parent : Wireland::Circuit, @data : BitArray, @bounds : Rectangle)
    super
    clear
  end

  def clear
    @state_queue.clear
    size.times { @state_queue << false }
  end
end
