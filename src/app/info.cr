module Wireland::App::Info
  class_getter id : UInt64? = nil

  MARGIN = 20
  SPACING = 1.0

  BG_WIDTH = Screen::WIDTH/2
  BG_HEIGHT = Screen::HEIGHT/2
  BG_X = BG_WIDTH/2
  BG_Y = BG_HEIGHT/2

  @@buttons = {} of R::Rectangle => Proc(Nil)
  @@connections_page = 0

  def self.set_id(new_id)
    reset
    @@id = new_id

    if App.circuit[new_id].connects.size > CONNECTIONS_MAX
      # Connection Buttons
      buttons = _get_connections_button_rects
      @@buttons[buttons[:prev]] = -> do
        @@connections_page -= 1
        @@connections_page = 0 if @@connections_page < 0
      end

      @@buttons[buttons[:next]] = -> do
        @@connections_page += 1 if App.circuit[new_id].connects.size > (@@connections_page + 1) * CONNECTIONS_MAX
      end
    end
  end

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

    
    out_text = "Out: #{App.circuit[id].connects.size}"
    out_text_length = R.measure_text_ex(App.font, size_text, STATS_TEXT_SIZE, SPACING).x

    out_text_rect = R::Rectangle.new(
      x:      x - out_text_length,
      y:      size_text_rect.y + size_text_rect.height + STATS_LINE_SPACING,
      width:  out_text_length,
      height: STATS_TEXT_SIZE
    )
    
    R.draw_text_ex(
      App.font,
      out_text,
      V2.new(
        x: out_text_rect.x,
        y: out_text_rect.y
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
  CONNECTIONS_MAX = 6

  BUTTON_SPACING = 74
  BUTTON_MARGIN = MARGIN/4
  BUTTON_SIZE = (BUTTON_SPACING/2) - BUTTON_MARGIN*2


  private def self._get_connection_rect(x, y, index = 0) : R::Rectangle
    R::Rectangle.new(
      x:      x + (index * (MARGIN + CONNECTION_SIZE)),
      y:      y,
      width:  CONNECTION_SIZE,
      height: CONNECTION_SIZE
    )
  end

  private def self._get_button_rects(x ,y) : NamedTuple(prev: R::Rectangle, next: R::Rectangle)
    prev_button_rect = R::Rectangle.new(
      x: x + BUTTON_MARGIN,
      y: y + CONNECTION_SIZE/2 - BUTTON_SIZE/2,
      width: BUTTON_SIZE,
      height: BUTTON_SIZE
    )

    next_button_rect = R::Rectangle.new(
      x: BG_X + BG_WIDTH - BUTTON_MARGIN - BUTTON_SIZE,
      y: y + CONNECTION_SIZE/2 - BUTTON_SIZE/2,
      width: BUTTON_SIZE,
      height: BUTTON_SIZE
    )

    {prev: prev_button_rect, next: next_button_rect}
  end

  private def self._get_connections_button_rects
    _get_button_rects(BG_X + CONNECTION_SIZE + BUTTON_MARGIN, BG_Y + MARGIN + NAME_TEXT_SIZE + MARGIN/2 + CONNECTION_SIZE/2 - BUTTON_SIZE/2)
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

    closest = _get_connection_rect(bg_rect.x + bg_rect.width, y, 0)
    farthest = _get_connection_rect(bg_rect.x + bg_rect.width, y, CONNECTIONS_MAX)

    connections_rect = R::Rectangle.new(
      x: closest.x,
      y: closest.y,
      width: (farthest.x + farthest.width) - closest.x,
      height: (farthest.y + farthest.height) - closest.y,
    )

    connections_rect.x += BUTTON_SPACING/2

    if App.circuit[id].connects.size > CONNECTIONS_MAX
      buttons = _get_connections_button_rects

      R.draw_rectangle_rec(
        buttons[:prev],
        App.palette.alt_wire
      )

      R.draw_rectangle_rec(
        buttons[:next],
        App.palette.alt_wire
      )
    end

    start = (CONNECTIONS_MAX * @@connections_page)
    finish = (CONNECTIONS_MAX * (@@connections_page + 1))

    if finish >= App.circuit[id].connects.size
      finish = App.circuit[id].connects.size - 1
    end

    App.circuit[id].connects[start..finish].each_with_index do |c_id, index|
      _draw_connection(c_id, connections_rect.x, connections_rect.y, index)
    end

    # @@buttons.keys.each do |r|
    #   R.draw_rectangle_rec(
    #     r,
    #     R.fade(R::RED, 0.5)
    #   )
    # end
  end

  private def self._draw_buffer_states
  end

  private def self._draw_pole_connections
  end

  private def self._draw_switch_connections
  end

  def self.reset
    @@id = nil

    @@buttons.clear
    @@connections_page = 0
  end

  def self.show?
    !@@id.nil?
  end

  private def self._handle_interact
    if R.mouse_button_released?(Mouse::INTERACT)
      @@buttons.any? do |rect, event|
        collides = R.check_collision_point_rec?(Mouse.position, rect)
        if collides
          event.call
        end

        collides
      end
    end
  end

  # When a component is right clicked, display a box.
  def self.update
    if !show? && R.mouse_button_released?(Mouse::INFO) && !Help.show?
      clicked = Mouse.get_component

      if clicked
        set_id(clicked.id)
      end
    elsif show?
      _handle_interact
      if [Mouse::CAMERA, Mouse::INFO].any? { |mb| R.mouse_button_released?(mb) }
        reset
      end
    end
  end
end