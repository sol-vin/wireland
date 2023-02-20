# A wire instruction like WIRE, ALTWIRE, JOIN, ETC
class Wireland::Component
  # Holds a list of all classes inheriting this class
  class_getter all : Array(Wireland::Component.class) = [] of Wireland::Component.class
  # Empty list for easier definition for components
  class_getter none : Array(Wireland::Component.class) = [] of Wireland::Component.class

  # Adds all inheriting types to the class list
  macro inherited
    Wireland::Component.all << {{@type.id}}
  end

  # Color of the component
  class_property color : R::Color = R::Color.new

  # Should we connect adjacently to another component of the same type to create a part.
  def self.allow_adjacent?
    false
  end

  # Should we connect diagonally to another component.
  def self.allow_diags?
    false
  end

  # Does this component delay execution?
  def self.active?
    false
  end

  def self.passive?
    !active?
  end

  # List of `Component` classes that this component should not pulse out to.
  def self.output_whitelist : Array(Wireland::Component.class)
    Wireland::Component.all.reject do |c| 
      c == Wireland::Component::Start || 
      c == Wireland::Component::Buffer || 
      c == Wireland::Component::DiodeOut || 
      c == Wireland::Component::NotOut ||
      c == Wireland::Component::InputOn || 
      c == Wireland::Component::InputOff || 
      c == Wireland::Component::InputToggleOn || 
      c == Wireland::Component::InputToggleOff
    end
  end

  # Link to the parent circuit
  getter parent : Wireland::Circuit

  # What this component is connected out to.
  property connects = [] of UInt64

  # The list of pulses incoming to this component from which component id.
  property pulses = [] of UInt64

  # The id of this component
  property id : UInt64 = 0_u64

  # Can this component conduct in and out? Used by relay poles to turn off and on a component.
  property? conductive : Bool = true

  getter bounds : Rectangle
  getter data : BitArray
  getter size : Int32

  def initialize(@parent : Wireland::Circuit, @data : BitArray, @bounds : Rectangle)
    @size = @data.count(true)
  end

  def [](x, y)
    raise "Out of bounds #{x}, #{y} : #{id}:#{self.class}" if x < 0 || y < 0 || x >= bounds[:width] || y >= bounds[:height]
    @data[x + y * bounds[:width]]
  end
  
  def []?(x, y)
    return nil if x < 0 || y < 0 || x >= bounds[:width] || y >= bounds[:height]
    @data[x + y * bounds[:width]]
  end

  def abs_data(x, y)
    abs_x = x - bounds[:x]
    abs_y = y - bounds[:y]

    self[abs_x, abs_y]
  end

  def abs_data?(x, y)
    abs_x = x - bounds[:x]
    abs_y = y - bounds[:y]

    self[abs_x, abs_y]?
  end

  def setup
  end

  def points : Array(Point)
    ps = [] of Point
    bounds[:width].times do |x|
      bounds[:height].times do |y|
         ps << {x: bounds[:x] + x, y: bounds[:y] + y} if self[x, y]
      end
    end
    ps
  end

  def color : R::Color
    self.class.color
  end

  # Has this component been pulsed this tick?
  def high?
    pulses.size > 0
  end

  # Has this component not been pulsed this tick?
  def low?
    pulses.size == 0
  end

  # Was this component pulsed by a component with `id`?
  def pulsed_by?(id)
    !!pulses[id]?
  end
  
  def pulse_out
    connects.each do |com_id|
      # Pulse our connecting parts, but only if we haven't pulsed it already.
      parent[com_id].pulse_in(self.id)
    end
  end

  def pulse_out(to_id : UInt64)
    parent[to_id].pulse_in(self.id)
  end

  def pulse_in(from_id : UInt64)
    if from_id == id
      raise "#{self.id} was pulsed by #{from_id} but it cannot pulse itself."
    end

    if conductive? && !pulses.includes? from_id
      # Add pulse to list of pulses in.
      pulses << from_id
      # Run the on_new_pulse event
      on_pulse(from_id)
    end
  end

  def terminal?
    connects.empty?
  end

  # Events
  # What to do when getting a pulse every tick
  def on_high
  end

  # What to do when not getting a pulse every tick
  def on_low
  end

  # Used by active components to handle end of tick behavior.
  def on_tick
  end

  # What should be done when this part receives a new charge from a new source
  def on_pulse(from_id : UInt64)
    pulse_out unless self.class.active? || pulses.size > 1
  end
end

