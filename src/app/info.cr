module Wireland::App::Info
  class_getter id : UInt64? = nil

  MARGIN = 20
  SPACING = 1.0

  BG_WIDTH = Screen::WIDTH/2
  BG_HEIGHT = Screen::HEIGHT/2
  BG_X = BG_WIDTH/2
  BG_Y = BG_HEIGHT/2


  # Draws an info box when id is valid
  def self.draw
    if (id = @@id) && !Help.show?
      # text = ""

      # text += "ID: #{id}"
      # text += "\nSize: #{App.circuit[id].size}"
      # text += "\n->: #{App.circuit[id].connects.size} - #{App.circuit[id].connects}"

      # if App.circuit[id].is_a?(Wireland::IO)
      #   io = App.circuit[id].as(Wireland::IO)
      #   text += "\nON: #{io.on?}"
      # elsif App.circuit[id].is_a?(Wireland::RelayPole)
      #   text += "\nHIGH: #{App.last_pulses.includes? id}"
      #   text += "\nCONDUCTIVE: #{App.circuit[id].conductive?}"
      # elsif App.circuit[id].class.active?
      #   text += "\nHIGH: #{App.last_pulses.includes? id}"
      #   text += "\nACTIVE: #{App.last_active_pulses.includes?(id)}"
      #   text += "\nWILL ACTIVE: #{App.circuit.active_pulses.keys.includes?(id)}"
      # else
      #   text += "\nHIGH: #{App.last_pulses.includes? id}"
      # end


      bg_rect = R::Rectangle.new(
        x:      BG_X,
        y:      BG_Y,
        width:  BG_WIDTH,
        height: BG_HEIGHT,
      )

      R.draw_rectangle(
        bg_rect.x,
        bg_rect.y,
        bg_rect.width,
        bg_rect.height,
        App.palette.wire
      )

      name_rect = _draw_name(id, bg_rect.x + MARGIN, bg_rect.y + MARGIN)
      _draw_stats(id, bg_rect.x + bg_rect.width - MARGIN, name_rect.y)
      _draw_connections_out(id, name_rect.x, name_rect.y + name_rect.height + MARGIN/2)
    end
  end

  NAME_TEXT_SIZE = 60
  NAME_BG_LINE_THICKNESS = 7

  private def self._draw_name(id, x, y) : R::Rectangle
    name = App.circuit[id].class.to_s.split("::").last

    name_length = R.measure_text_ex(App.font, name, NAME_TEXT_SIZE, SPACING).x

    name_rect = R::Rectangle.new(
      x:      x,
      y:      y,
      width:  name_length,
      height: NAME_TEXT_SIZE,
    )

    name_lines = R::Rectangle.new(
      x:      name_rect.x - NAME_BG_LINE_THICKNESS*2,
      y:      name_rect.y - NAME_BG_LINE_THICKNESS*2,
      width:  name_rect.width + NAME_BG_LINE_THICKNESS*3,
      height: name_rect.height + NAME_BG_LINE_THICKNESS*4,
    )

    color = App.circuit[id].class.color

    color = App.palette.bg if App.circuit[id].is_a?(Wireland::Component::Wire)

    R.draw_rectangle_lines_ex(
      name_lines,
      NAME_BG_LINE_THICKNESS,
      color
    )

    R.draw_text_ex(
      App.font,
      name,
      V2.new(
        x: name_rect.x,
        y: name_rect.y
      ),
      NAME_TEXT_SIZE,
      SPACING,
      App.palette.bg
    )

    name_lines
  end

  STATS_TEXT_SIZE = (NAME_TEXT_SIZE - MARGIN/2) / 2
  STATS_LINE_SPACING = MARGIN/2

  private def self._draw_stats(id, x, y)
    id_text = "ID: 0x#{id.to_s(16).upcase}"
    id_text_length = R.measure_text_ex(App.font, id_text, STATS_TEXT_SIZE, SPACING).x

    id_text_rect = R::Rectangle.new(
      x:      x - id_text_length,
      y:      y,
      width:  id_text_length,
      height: STATS_TEXT_SIZE
    )

    R.draw_text_ex(
      App.font,
      id_text,
      V2.new(
        x: id_text_rect.x,
        y: id_text_rect.y
      ),
      STATS_TEXT_SIZE,
      SPACING,
      App.palette.bg
    )

    size_text = "Size: #{App.circuit[id].size}"
    size_text_length = R.measure_text_ex(App.font, size_text, STATS_TEXT_SIZE, SPACING).x

    size_text_rect = R::Rectangle.new(
      x:      x - size_text_length,
      y:      id_text_rect.y + id_text_rect.height + STATS_LINE_SPACING,
      width:  size_text_length,
      height: STATS_TEXT_SIZE
    )
    
    R.draw_text_ex(
      App.font,
      size_text,
      V2.new(
        x: size_text_rect.x,
        y: size_text_rect.y
      ),
      STATS_TEXT_SIZE,
      SPACING,
      App.palette.bg
    )
  end

  private def self._draw_active
  end

  private def self._draw_high_low
  end

  private def self._draw_conductive
  end

  # Connections
  CONNECTION_SIZE = 50
  CONNECTION_BG_LINE_THICKNESS = 3.5
  CONNECTION_TEXT_SIZE = 15
  CONNECTION_RANGE = (0..6)



  private def self._get_connection_rect(x, y, index = 0) : R::Rectangle
    R::Rectangle.new(
      x:      x + (index * (MARGIN + CONNECTION_SIZE)),
      y:      y,
      width:  CONNECTION_SIZE,
      height: CONNECTION_SIZE
    )
  end

  private def self._draw_connection(id, x, y, index = 0)
    bg_rect = _get_connection_rect(x, y, index)

    R.draw_rectangle_rec(
      bg_rect,
      App.circuit[id].class.color
    )

    R.draw_rectangle_lines_ex(
      bg_rect,
      CONNECTION_BG_LINE_THICKNESS,
      App.palette.bg
    )

    
    id_text = "0x#{id.to_s(16)}"
    id_text_length = R.measure_text_ex(App.font, id_text, CONNECTION_TEXT_SIZE, SPACING).x

    id_text_rect = R::Rectangle.new(
      x:      x + CONNECTION_SIZE/2 - id_text_length/2 + (index * (MARGIN + CONNECTION_SIZE)),
      y:      y + CONNECTION_SIZE/2 - CONNECTION_TEXT_SIZE/2,
      width:  id_text_length,
      height: CONNECTION_TEXT_SIZE
    )

    R.draw_text_ex(
      App.font,
      id_text,
      V2.new(
        x: id_text_rect.x,
        y: id_text_rect.y
      ),
      CONNECTION_TEXT_SIZE,
      SPACING,
      App.palette.bg
    )
  end

  private def self._draw_connections_in
  end

  private def self._draw_connections_out(id, x, y)
    bg_rect = R::Rectangle.new(
      x:      x,
      y:      y,
      width:  CONNECTION_SIZE,
      height: CONNECTION_SIZE
    )

    R.draw_rectangle_lines_ex(
      bg_rect,
      CONNECTION_BG_LINE_THICKNESS,
      App.palette.alt_wire
    )

    out_text = "Out:"
    out_text_length = R.measure_text_ex(App.font, out_text, CONNECTION_TEXT_SIZE, SPACING).x

    out_text_rect = R::Rectangle.new(
      x:      x + CONNECTION_SIZE/2 - out_text_length/2,
      y:      y + CONNECTION_SIZE/2 - CONNECTION_TEXT_SIZE/2,
      width:  out_text_length,
      height: CONNECTION_TEXT_SIZE
    )

    R.draw_text_ex(
      App.font,
      "Out:",
      V2.new(
        x: out_text_rect.x,
        y: out_text_rect.y
      ),
      CONNECTION_TEXT_SIZE,
      SPACING,
      App.palette.bg
    )

    closest = _get_connection_rect(bg_rect.x + bg_rect.width, y, CONNECTION_RANGE.begin)
    farthest = _get_connection_rect(bg_rect.x + bg_rect.width, y, CONNECTION_RANGE.end)

    connections_rect = R::Rectangle.new(
      x: closest.x,
      y: closest.y,
      width: (farthest.x + farthest.width) - closest.x,
      height: (farthest.y + farthest.height) - closest.y,
    )

    button_spacing = (BG_X + BG_WIDTH) - (connections_rect.x + connections_rect.width)
    connections_rect.x += button_spacing/2

    if App.circuit[id].connects.size > CONNECTION_RANGE.size
      button_margin = MARGIN/4
      button_size = (button_spacing/2) - button_margin*2
      
      button_rect = R::Rectangle.new(
        x: bg_rect.x + bg_rect.width + button_margin,
        y: bg_rect.y + CONNECTION_SIZE/2 - button_size/2,
        width: button_size,
        height: button_size
      )

      R.draw_rectangle_rec(
        button_rect,
        App.palette.alt_wire
      )

      button_rect = R::Rectangle.new(
        x: connections_rect.x + connections_rect.width + button_margin,
        y: bg_rect.y + CONNECTION_SIZE/2 - button_size/2,
        width: button_size,
        height: button_size
      )

      R.draw_rectangle_rec(
        button_rect,
        App.palette.alt_wire
      )
    end


    App.circuit[id].connects[0..6].each_with_index do |c_id, index|
      _draw_connection(c_id, connections_rect.x, connections_rect.y, index)
    end
  end

  private def self._draw_buffer_states
  end

  private def self._draw_pole_connections
  end

  private def self._draw_switch_connections
  end

  def self.reset
    @@id = nil
  end

  def self.show?
    !@@id.nil?
  end

  private def self._handle_interact

  end

  # When a component is right clicked, display a box.
  def self.update
    if !show? && R.mouse_button_released?(Mouse::INFO) && !Help.show?
      clicked = Mouse.get_component

      if clicked
        @@id = clicked.id
      end
    elsif show?
      _handle_interact
    elsif [Mouse::CAMERA, Mouse::INFO].any? { |mb| R.mouse_button_released?(mb) }
      reset
    end
  end
end