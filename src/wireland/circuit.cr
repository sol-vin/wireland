require "raylib-cr"
require "bit_array"

alias R = Raylib
alias V2 = R::Vector2
alias W = Wireland
alias WC = Wireland::Component

alias Rectangle = NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
alias Point = NamedTuple(x: Int32, y: Int32)

# The whole simulated program
class Wireland::Circuit
  def load(image : R::Image, palette : Wireland::Palette = Wireland::Palette::DEFAULT)
    raise "No file" if image.width == 0

    @width = image.width
    @height = image.height

    palette.load_into_components
    start_time = R.get_time

    component_points = {} of WC.class => Array(Point)

    WC.all.each { |c| component_points[c] = [] of Point }
    image.width.times do |x|
      image.height.times do |y|
        color = R.get_image_color(image, x, y)
        if component = WC.all.find { |c| c.color == color }
          component_points[component] << {x: x, y: y}
        end
      end
    end

    components = [] of WC
    id = 0_u64

    component_points.each do |component_class, xy_data|
      until xy_data.empty?
        shape = _get_component_shape(xy_data, component_class)

        component = component_class.new(self, shape[:data], shape[:bounds])
        component.id = id
        components << component
        id += 1
      end
    end
    # puts "Components shaped in #{R.get_time - start_time}"


    adjacent = [
      {x: 0, y: -1},
      {x: -1, y: 0},
      {x: 0, y: 1},
      {x: 1, y: 0},
    ]

    start_time = R.get_time
    # Connect each of the components
    components.each do |component|
      # Select only components that are valid output destinations
      valid_components = components.select do |c|
        c.id != component.id &&
        component.class.output_whitelist.includes?(c.class) &&
        _rect_intersects?(c.bounds, component.bounds)
      end

      valid_components.each do |valid_component|
        # Calculate intersection
        left_x = Math.max(valid_component.bounds[:x], component.bounds[:x])
        right_x = Math.min(valid_component.bounds[:x] + valid_component.bounds[:width], component.bounds[:x] + component.bounds[:width])
        top_y = Math.max(valid_component.bounds[:y], component.bounds[:y])
        bottom_y = Math.min(valid_component.bounds[:y] + valid_component.bounds[:height], component.bounds[:y] + component.bounds[:height])

        intersection = {
          x: left_x - 1,
          y: top_y - 1,
          width:right_x - left_x + 2,
          height: bottom_y - top_y + 2
        }

        next if [intersection[:width], intersection[:height]].any?{|i| i <= 0}

        neighbors = (intersection[:x]..(intersection[:x]+intersection[:width])).any? do |x|
          (intersection[:y]..(intersection[:y]+intersection[:height])).any? do |y|
            component.abs_data?(x, y) && adjacent.any? {|a_p| valid_component.abs_data?(x + a_p[:x], y + a_p[:y]) }
          end
        end

        component.connects << valid_component.id if neighbors
      end
    end
    # puts "Components connected in #{R.get_time - start_time}"
    @last_id = components.sort { |a,b| b.id <=> a.id }[0].id

    @components = components
    components.each(&.setup)
    components
  end
  
  private def _rect_intersects?(a : Rectangle, b : Rectangle)
    R.check_collision_recs?(
      R::Rectangle.new(
        x: a[:x] - 1,
        y: a[:y] - 1,
        width: a[:width] + 2,
        height: a[:height] + 2,
      ),

      R::Rectangle.new(
        x: b[:x] - 1,
        y: b[:y] - 1,
        width: b[:width] + 2,
        height: b[:height] + 2,
      )
    )
  end

  private def _get_component_shape(xy_data, component_class)
    shape = [] of Point
    new_points = [xy_data.pop] of Point

    until new_points.empty?
      point = new_points.pop
      shape << point

      all_points = new_points + shape

      if component_class == WC::Tunnel
        connected_tunnels = xy_data.select{|xy| xy[:x] == point[:x] || xy[:y] == point[:y]}
        connected_tunnels.each{|t| xy_data.delete t}
        new_points.concat(connected_tunnels - all_points)
      else
        # Make the neighborhood and remove anything we already have in our list of points to explore.
        neighborhood = _make_neighborhood(point, component_class) - all_points
        connected_pixels = xy_data.select{|xy| neighborhood.any?{|nxy| nxy == xy}}
        connected_pixels.each{|p| xy_data.delete p}
        new_points.concat(connected_pixels)
      end
    end


    b_x = shape.min_by {|a| a[:x]}[:x]
    b_y = shape.min_by {|a| a[:y]}[:y]
    b_x_max = shape.max_by {|a| a[:x]}[:x]
    b_y_max = shape.max_by {|a| a[:y]}[:y]
    b_width = b_x_max - b_x + 1
    b_height = b_y_max - b_y + 1

    shape_data = BitArray.new(b_width * b_height)
    shape.each { |xy| shape_data[(xy[:x] - b_x) + (xy[:y] - b_y)  * b_width] = true } 

    # Output
    {
      bounds: {
        x: b_x,
        y: b_y,
        width: b_width,
        height: b_height,
      },

      data: shape_data
    }
  end

  # Creates a list of neighbor points around xy.
  private def _make_neighborhood(xy : Point, com : WC.class)
    diags = [
      {x: -1, y: -1},
      {x: -1, y: 1},
      {x: 1, y: -1},
      {x: 1, y: 1},
    ]

    adjacent = [
      {x: 0, y: -1},
      {x: -1, y: 0},
      {x: 0, y: 1},
      {x: 1, y: 0},
    ]

    r_points = [] of Point
    r_points += diags if com.allow_diags?
    r_points += adjacent if com.allow_adjacent?

    r_points.map { |r_p| {x: xy[:x] + r_p[:x], y: xy[:y] + r_p[:y]} }
  end

  # Palette of colors that will be loaded into our component classes.
  property palette : Wireland::Palette = Wireland::Palette::DEFAULT

  # List of all components in this circuit
  property components = [] of WC
  # Number of ticks that have run since the circuit started.
  property ticks = 0_u128

  property width = 0
  property height = 0

  getter last_id = 0_u64

  # List of pulses that need to
  getter active_pulses = {} of UInt64 => Array(UInt64)

  def initialize
  end

  def initialize(filename : String, palette_file : String)
    @palette = Wireland::Palette.new(palette_file)
    load(image, @palette)
    R.unload_image image
    reset
  end

  def initialize(filename : String, @palette : Wireland::Palette = Wireland::Palette::DEFAULT)
    image = R.load_image(filename)
    load(image, @palette)
    R.unload_image image
    reset
  end

  def initialize(image : R::Image, @palette : Wireland::Palette = Wireland::Palette::DEFAULT)
    load(image, palette)
    reset
  end

  # Gets a component at index
  def [](index)
    components[index]
  end

  # Gets a component at index but with a question mark. :)
  def []?(index)
    components[index]?
  end

  # Queues up a list of active pulses for the next tick. Used by active components.
  def active_pulse(id, to : Array(UInt64))
    if active_pulses[id]?
      active_pulses[id].concat to
    else
      active_pulses[id] = to.dup
    end
  end

  # Queues up an active pulses for the next tick. Used by active components.
  def active_pulse(id, to : UInt64)
    if arr = active_pulses[id]?
      arr << to
    else
      active_pulses[id] = [to]
    end
  end

  def pulse_inputs
    inputs = components.select(&.is_a?(WC::InputOn | WC::InputOff | WC::InputToggleOn | WC::InputToggleOff)).map(&.as(Wireland::IO))
    inputs.select(&.on?).each { |i| active_pulse(i.id, i.connects) }
    off_inputs = inputs.select(&.off?).map(&.id)
    @active_pulses.reject!{|c| off_inputs.includes? c}
  end

  def pre_tick
    active_pulses.each do |from, pulses|
      pulses.each do |to|
        self[from].pulse_out to
      end
    end
  end

  def mid_tick
    active_pulses.clear

    components.each do |c|
      if c.high?
        c.on_high
      else
        c.on_low
      end
    end
  end

  def post_tick
    # Turn off all the poles, then flip them back on via on_tick where needed
    components.map(&.as?(Wireland::RelayPole)).compact.each { |pole| pole.as(Wireland::RelayPole).off }
    components.map(&.as?(WC::InputOff)).compact.each(&.off)
    components.map(&.as?(WC::InputOn)).compact.each(&.on)

    components.each(&.on_tick)
    # Clear out all the pulses to start the next tick.
    components.each(&.pulses.clear)
  end

  def increase_ticks
    @ticks += 1
  end

  # Main logic route for the circuit
  def tick
    increase_ticks
    pulse_inputs
    pre_tick
    mid_tick
    post_tick
  end

  # Resets the circuit to tick 0
  def reset
    @ticks = 0
    active_pulses.clear
    components.map(&.as?(WC::Buffer)).compact.each(&.clear)
    components.each(&.pulses.clear)
    components.map(&.as?(Wireland::RelayPole)).compact.each { |pole| pole.as(Wireland::RelayPole).off }
    components.map(&.as?(WC::InputOff)).compact.each(&.off)
    components.map(&.as?(WC::InputOn)).compact.each(&.on)
    components.map(&.as?(WC::InputToggleOff)).compact.each(&.off)
    components.map(&.as?(WC::InputToggleOn)).compact.each(&.on)
    components.map(&.as?(WC::OutputOff)).compact.each(&.off)
    components.map(&.as?(WC::OutputOn)).compact.each(&.on)
    components.each(&.on_tick)
  end
end
