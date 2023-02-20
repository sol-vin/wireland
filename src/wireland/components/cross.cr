class Wireland::Component::Cross < Wireland::Component
  # This can technically only have a total of 4 directions
  getter directions = {} of Wireland::Direction => UInt64

  def initialize(@parent : Wireland::Circuit, @data : BitArray, @bounds : Rectangle)
    super
  end

  def setup
    adjacent_directions = {
      Wireland::Direction::Up    => {x: 0, y: -1},
      Wireland::Direction::Down  => {x: 0, y: 1},
      Wireland::Direction::Left  => {x: -1, y: 0},
      Wireland::Direction::Right => {x: 1, y: 0},
    }

    one_way_connections = parent.components.select(&.is_a?(Wireland::Component::Start | Wireland::Component::Buffer | Wireland::Component::DiodeOut | Wireland::Component::NotOut | Wireland::Component::InputOn | Wireland::Component::InputOff | Wireland::Component::InputToggleOn | Wireland::Component::InputToggleOff)).select do |c|
      c.connects.includes? self.id
    end.map(&.id)

    (one_way_connections + connects).each do |c|
      direction = Wireland::Direction::None
      parent[c].points.each do |c_point|
        adjacent_directions.select { |d, a| points.includes?({x: c_point[:x] + a[:x], y: c_point[:y] + a[:y]}) }.keys.each do |d|
          direction |= d
        end
      end

      if direction != Wireland::Direction::None
        directions[direction] = c
      end
    end
  end

  # Special on_new_pulse to send the pulse to the correct place.
  def on_pulse(from_id : UInt64)
    if d = directions.find { |d, c_id| c_id == from_id }
      d[0].each do |d|
        if d_id = directions.find { |k, _| k.includes? d.flip }
          pulse_out(d_id[1]) if connects.includes? d_id[1]
          true
        else
          false
        end
      end
    else
      raise "Cross: Unknown Direction from id #{from_id} which is a #{parent[from_id]}"
    end
  end
end
