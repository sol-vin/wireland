module Wireland::App::Info
  class_getter id : UInt64? = nil

  MARGIN  =  20
  SPACING = 1.0

  BG_WIDTH  = Screen::WIDTH/2
  BG_HEIGHT = Screen::HEIGHT/2
  BG_X      = BG_WIDTH/2
  BG_Y      = BG_HEIGHT/2

  BG_RECT = R::Rectangle.new(
    x: BG_X,
    y: BG_Y,
    width: BG_WIDTH,
    height: BG_HEIGHT,
  )

  # Name
  NAME_TEXT_SIZE         = 60
  NAME_BG_LINE_THICKNESS =  7

  NAME_X      = BG_X + MARGIN
  NAME_Y      = BG_Y + MARGIN
  NAME_WIDTH  = BG_WIDTH*0.75
  NAME_HEIGHT = NAME_TEXT_SIZE

  NAME_RECT = R::Rectangle.new(
    x: NAME_X,
    y: NAME_Y,
    width: NAME_WIDTH,
    height: NAME_HEIGHT,
  )

  # Stats
  STATS_LINE_SPACING = MARGIN/2
  STATS_TEXT_SIZE    = (NAME_TEXT_SIZE - STATS_LINE_SPACING)/3

  STATS_X = BG_X + BG_WIDTH - MARGIN
  STATS_Y = NAME_Y

  # Connections
  CONNECTIONS_X = NAME_X
  CONNECTIONS_Y = NAME_Y + NAME_HEIGHT + MARGIN

  CONNECTION_SIZE              =  50
  CONNECTION_BG_LINE_THICKNESS = 3.5
  CONNECTION_TEXT_SIZE         =  15
  CONNECTIONS_MAX              =   7

  CONNECTIONS_START_X = NAME_X + CONNECTION_SIZE + CONNECTIONS_BUTTON_SPACING/2

  CONNECTION_BUTTON_MARGIN = MARGIN * 0.75
  CONNECTIONS_FARTHEST_X = CONNECTIONS_START_X + ((CONNECTIONS_MAX - 1) * (CONNECTION_BUTTON_MARGIN + CONNECTION_SIZE)) + MARGIN/2

  CONNECTION_BUTTON_NAMES = [
    :button0,
    :button1,
    :button2,
    :button3,
    :button4,
    :button5,
    :button6,
  ]

  CONNECTIONS_BUTTON_SPACING = 74
  CONNECTIONS_BUTTON_MARGIN  = MARGIN/4
  CONNECTIONS_BUTTON_SIZE    = (CONNECTIONS_BUTTON_SPACING/2) - CONNECTIONS_BUTTON_MARGIN*2

  CONNECTIONS_PREV_BUTTON_RECT = R::Rectangle.new(
    x: CONNECTIONS_X + CONNECTION_SIZE + CONNECTIONS_BUTTON_MARGIN,
    y: CONNECTIONS_Y + CONNECTION_SIZE/2 - CONNECTIONS_BUTTON_SIZE/2,
    width: CONNECTIONS_BUTTON_SIZE,
    height: CONNECTIONS_BUTTON_SIZE
  )

  CONNECTIONS_NEXT_BUTTON_RECT = R::Rectangle.new(
    x: BG_X + BG_WIDTH - CONNECTIONS_BUTTON_MARGIN - CONNECTIONS_BUTTON_SIZE,
    y: CONNECTIONS_Y + CONNECTION_SIZE/2 - CONNECTIONS_BUTTON_SIZE/2,
    width: CONNECTIONS_BUTTON_SIZE,
    height: CONNECTIONS_BUTTON_SIZE
  )

  alias ButtonEvent = NamedTuple(rectangle: R::Rectangle, event: Proc(Nil))

  @@buttons = {} of Symbol => ButtonEvent
  @@connections_page = 0

  private def self._make_connection_buttons
    CONNECTION_BUTTON_NAMES.each do |name|
      @@buttons.delete(name)
    end
    if id = @@id
      start = ((CONNECTIONS_MAX - 1) * @@connections_page)
      finish = ((CONNECTIONS_MAX - 1) * (@@connections_page + 1))

      list = App.circuit[id].connects
      if switch = App.circuit[id].as? Component::Switch
        list = switch.poles.map(&.as(Component).id)
      end

      if finish >= list.size
        finish = list.size - 1
      end

      list[start..finish].each_with_index do |c_id, index|
        @@buttons[CONNECTION_BUTTON_NAMES[index]] = {rectangle: _get_connection_rect(index), event: ->do
          set_id(c_id)
        end}
      end
    end
  end

  def self.set_id(id)
    reset
    @@id = id
    _make_connection_buttons
    if App.circuit[id].connects.size > CONNECTIONS_MAX - 1
      # Connection Buttons

      items = App.circuit[id].connects

      if switch = App.circuit[id].as?(Component::Switch)
        items = switch.poles.map(&.as(Component).id)
      end

      @@buttons[:prev] = {rectangle: CONNECTIONS_PREV_BUTTON_RECT, event: ->do
        @@connections_page -= 1 unless @@connections_page <= 0
        _make_connection_buttons
      end}

      @@buttons[:next] = {rectangle: CONNECTIONS_NEXT_BUTTON_RECT, event: ->do
        @@connections_page += 1 if items.size > (@@connections_page + 1) * CONNECTIONS_MAX - 1
        _make_connection_buttons
      end}
    end
  end

  # Draws an info box when id is valid
  def self.draw
    if (id = @@id)
      R.draw_rectangle_rec(
        BG_RECT,
        App.palette.wire
      )

      _draw_name
      _draw_stats
      _draw_connections_out
    end
  end

  private def self._draw_name
    if id = @@id
      name = App.circuit[id].class.to_s.split("::").last

      name_length = R.measure_text_ex(Assets.font, name, NAME_TEXT_SIZE, SPACING).x

      name_rect = R::Rectangle.new(
        x: BG_X + MARGIN,
        y: BG_Y + MARGIN,
        width: name_length,
        height: NAME_TEXT_SIZE,
      )

      name_lines = R::Rectangle.new(
        x: name_rect.x - NAME_BG_LINE_THICKNESS*2,
        y: name_rect.y - NAME_BG_LINE_THICKNESS*2,
        width: name_rect.width + NAME_BG_LINE_THICKNESS*3,
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
        Assets.font,
        name,
        V2.new(
          x: name_rect.x,
          y: name_rect.y
        ),
        NAME_TEXT_SIZE,
        SPACING,
        App.palette.bg
      )
    end
  end

  private def self._draw_stats
    if id = @@id
      id_text = "ID: 0x#{id.to_s(16).upcase}"
      id_text_length = R.measure_text_ex(Assets.font, id_text, STATS_TEXT_SIZE, SPACING).x

      id_text_rect = R::Rectangle.new(
        x: STATS_X - id_text_length,
        y: STATS_Y,
        width: id_text_length,
        height: STATS_TEXT_SIZE
      )

      R.draw_text_ex(
        Assets.font,
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
      size_text_length = R.measure_text_ex(Assets.font, size_text, STATS_TEXT_SIZE, SPACING).x

      size_text_rect = R::Rectangle.new(
        x: STATS_X - size_text_length,
        y: id_text_rect.y + id_text_rect.height + STATS_LINE_SPACING,
        width: size_text_length,
        height: STATS_TEXT_SIZE
      )

      R.draw_text_ex(
        Assets.font,
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
      out_text_length = R.measure_text_ex(Assets.font, size_text, STATS_TEXT_SIZE, SPACING).x

      out_text_rect = R::Rectangle.new(
        x: STATS_X - out_text_length,
        y: size_text_rect.y + size_text_rect.height + STATS_LINE_SPACING,
        width: out_text_length,
        height: STATS_TEXT_SIZE
      )

      R.draw_text_ex(
        Assets.font,
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
  end

  private def self._draw_active
  end

  private def self._draw_high_low
  end

  private def self._draw_conductive
  end

  # Connections

  private def self._get_connection_rect(index) : R::Rectangle
    R::Rectangle.new(
      x: CONNECTIONS_START_X + (index * (CONNECTION_BUTTON_MARGIN + CONNECTION_SIZE)) + MARGIN/2,
      y: CONNECTIONS_Y,
      width: CONNECTION_SIZE,
      height: CONNECTION_SIZE
    )
  end

  private def self._draw_connection(id, index = 0)
    bg_rect = _get_connection_rect(index)

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
    id_text_length = R.measure_text_ex(Assets.font, id_text, CONNECTION_TEXT_SIZE, SPACING).x

    id_text_rect = R::Rectangle.new(
      x: bg_rect.x + CONNECTION_SIZE/2 - id_text_length/2,
      y: bg_rect.y + CONNECTION_SIZE/2 - CONNECTION_TEXT_SIZE/2,
      width: id_text_length,
      height: CONNECTION_TEXT_SIZE
    )

    R.draw_text_ex(
      Assets.font,
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

  private def self._draw_connections_out
    if id = @@id
      items = App.circuit[id].connects

      if switch = App.circuit[id].as?(Component::Switch)
        items = switch.poles.map(&.as(Component).id)
      end

      out_rect = R::Rectangle.new(
        x: CONNECTIONS_X,
        y: CONNECTIONS_Y,
        width: CONNECTION_SIZE,
        height: CONNECTION_SIZE
      )

      R.draw_rectangle_lines_ex(
        out_rect,
        CONNECTION_BG_LINE_THICKNESS,
        App.palette.alt_wire
      )

      out_text = App.circuit[id].is_a?(Component::Switch) ? "Poles" : "Out"
      out_text_length = R.measure_text_ex(Assets.font, out_text, CONNECTION_TEXT_SIZE, SPACING).x

      out_text_rect = R::Rectangle.new(
        x: CONNECTIONS_X + CONNECTION_SIZE/2 - out_text_length/2,
        y: CONNECTIONS_Y + CONNECTION_SIZE/2 - CONNECTION_TEXT_SIZE/2,
        width: out_text_length,
        height: CONNECTION_TEXT_SIZE
      )

      R.draw_text_ex(
        Assets.font,
        out_text,
        V2.new(
          x: out_text_rect.x,
          y: out_text_rect.y
        ),
        CONNECTION_TEXT_SIZE,
        SPACING,
        App.palette.bg
      )

      if items.size > CONNECTIONS_MAX - 1
        play_texture_rect = R::Rectangle.new(
          x: 0,
          y: 0,
          width: -Assets::Textures.play.width,
          height: -Assets::Textures.play.height
        )

        if @@connections_page != 0
          R.draw_rectangle_rec(
            CONNECTIONS_PREV_BUTTON_RECT,
            App.palette.alt_wire
          )

          R.draw_texture_pro(
            Assets::Textures.play,
            play_texture_rect,
            CONNECTIONS_PREV_BUTTON_RECT,
            V2.zero,
            0,
            App.palette.bg
          )
        end

        if @@connections_page != (items.size / CONNECTIONS_MAX).to_i
          R.draw_rectangle_rec(
            CONNECTIONS_NEXT_BUTTON_RECT,
            App.palette.alt_wire
          )

          play_texture_rect = R::Rectangle.new(
            x: 0,
            y: 0,
            width: Assets::Textures.play.width,
            height: Assets::Textures.play.height
          )

          R.draw_texture_pro(
            Assets::Textures.play,
            play_texture_rect,
            CONNECTIONS_NEXT_BUTTON_RECT,
            V2.zero,
            0,
            App.palette.bg
          )
        end
      end

      start = ((CONNECTIONS_MAX - 1) * @@connections_page)
      finish = ((CONNECTIONS_MAX - 1) * (@@connections_page + 1))

      if finish >= items.size
        finish = items.size - 1
      end

      items[start..finish].each_with_index do |c_id, index|
        _draw_connection(c_id, index)
      end

      # @@buttons.keys.each do |r|
      #   R.draw_rectangle_rec(
      #     r,
      #     R.fade(R::RED, 0.5)
      #   )
      # end
    end
  end

  private def self._draw_buffer_states
  end

  private def self._draw_pole_connections
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
      @@buttons.any? do |name, data|
        collides = R.check_collision_point_rec?(Mouse.position, data[:rectangle])
        if collides
          data[:event].call
        end

        collides
      end
    end
  end

  # When a component is right clicked, display a box.
  def self.update
    if !show? && R.mouse_button_released?(Mouse::INFO)
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
