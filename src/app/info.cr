module Wireland::App::Info
  class_getter id : UInt64? = nil

  # Draws an info box when id is valid
  def self.draw
    if (id = @@id) && !Help.show?
      text = ""

      text += "ID: #{id}"
      text += "\nSize: #{App.circuit[id].size}"
      text += "\n->: #{App.circuit[id].connects.size} - #{App.circuit[id].connects}"

      if App.circuit[id].is_a?(Wireland::IO)
        io = App.circuit[id].as(Wireland::IO)
        text += "\nON: #{io.on?}"
      elsif App.circuit[id].is_a?(Wireland::RelayPole)
        text += "\nHIGH: #{App.last_pulses.includes? id}"
        text += "\nCONDUCTIVE: #{App.circuit[id].conductive?}"
      elsif App.circuit[id].class.active?
        text += "\nHIGH: #{App.last_pulses.includes? id}"
        text += "\nACTIVE: #{App.last_active_pulses.includes?(id)}"
        text += "\nWILL ACTIVE: #{App.circuit.active_pulses.keys.includes?(id)}"
      else
        text += "\nHIGH: #{App.last_pulses.includes? id}"
      end

      App.draw_box("#{App.circuit[id].class.to_s.split("::").last}", text)
    end
  end

  def self.reset
    @@id = nil
  end

  def self.show?
    !@@id.nil?
  end

  # When a component is right clicked, display a box.
  def self.update
    if !show? && R.mouse_button_released?(Mouse::INFO) && !Help.show?
      clicked = Mouse.get_component

      if clicked
        @@id = clicked.id
      end
    elsif [Mouse::CAMERA, Mouse::INTERACT, Mouse::INFO].any? { |mb| R.mouse_button_released?(mb) }
      reset
    end
  end
end