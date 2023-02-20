require "./wireland"

# Button layout

# ? - Help
# Space - Tick
# Q - Show Pulses
# R - Reset

module Wireland::App
  module Scale
    CIRCUIT         = 4.0
    CIRCUIT_HALF    = CIRCUIT/2.0
    CIRCUIT_QUARTER = CIRCUIT/4.0
  end

  module Screen
    WIDTH  = 1200
    HEIGHT =  800
    SIZE   = V2.new(x: WIDTH, y: HEIGHT)

    module Zoom
      # Smallest zoom possible
      LIMIT_LOWER = 0.11_f32
      # Largest zoom possible
      LIMIT_UPPER = 12.0_f32
      # Unit to move zoom by
      UNIT    = 0.1
      DEFAULT = 2.0
    end
  end

  module Keys
    HELP         = R::KeyboardKey::Slash
    PULSES       = R::KeyboardKey::Q
    SOLID_PULSES = R::KeyboardKey::W
    TICK         = R::KeyboardKey::Space
    RESET        = R::KeyboardKey::R
    PLAY         = R::KeyboardKey::Enter

    @@tick_hold_time = 0.0
    @@tick_long_hold_time = 0.0
    @@tick_long_hold = false

    # Handles what keys do when pressed.
    def self.update
      if App.is_circuit_loaded?
        if R.key_released?(Keys::HELP) && !Info.show?
          Help.toggle
        end

        if !Help.show?
          if R.key_released?(Keys::PULSES)
            App.show_pulses = !App.show_pulses?
          end

          if R.key_released?(Keys::SOLID_PULSES)
            App.solid_pulses = !App.solid_pulses?
          end

          if R.key_released?(Keys::PLAY) && R.key_up?(Keys::TICK)
            App.play = !App.play?
            App.play_time = R.get_time
          end

          # Tick when play is enabled
          if App.play? && ((R.get_time - App.play_time) > App.play_speeds[App.play_speed])
            App.tick
            App.play_time = R.get_time
          end

          # Handle spacebar tick. When held down play
          if !App.play?
            if R.key_pressed?(Keys::TICK)
              @@tick_hold_time = R.get_time
            end

            if R.key_down?(Keys::TICK) && (R.get_time - @@tick_hold_time) > 1.0 && !@@tick_long_hold
              @@tick_long_hold_time = R.get_time
              @@tick_long_hold = true
            end

            if (R.key_released?(Keys::TICK) && !@@tick_long_hold) || (R.key_down?(Keys::TICK) && @@tick_long_hold && (R.get_time - @@tick_long_hold_time) > 0.1)
              App.tick
            elsif R.key_up?(Keys::TICK) && @@tick_long_hold
              @@tick_long_hold = false
            end
          end

          if R.key_released?(Keys::RESET)
            App.reset
          end

          if R.key_released?(R::KeyboardKey::Up)
            App.play_speed -= 1
            App.play_speed = 0 if App.play_speed < 0
          elsif R.key_released?(R::KeyboardKey::Down)
            App.play_speed += 1
            App.play_speed = App.play_speeds.size - 1 if App.play_speed >= App.play_speeds.size
          end
        end
      end
    end
  end

  module Mouse
    CAMERA   = R::MouseButton::Middle
    INTERACT = R::MouseButton::Left
    INFO     = R::MouseButton::Right

    SCALE = 2.0

    class_getter position = V2.new
    class_getter cursor_texture = R::Texture.new
    class_getter small_cursor_texture = R::Texture.new
    class_getter selector_texture = R::Texture.new

    @@previous_camera_mouse_drag_pos = V2.zero

    CURSOR_TEXTURE_FILE       = "rsrc/sim/cursor.png"
    SMALL_CURSOR_TEXTURE_FILE = "rsrc/sim/smallcursor.png"
    SELECTOR_TEXTURE_FILE     = "rsrc/sim/selector.png"

    SMALL_CURSOR_ZOOM_LIMIT = 5.0

    def self.update
      @@position.x = R.get_mouse_x
      @@position.y = R.get_mouse_y
    end

    def self.get_component
      world_mouse = R.get_screen_to_world_2d(Mouse.position, App.camera)
      offset = App.circuit_texture.width/2.0
      x = (world_mouse.x / Scale::CIRCUIT).to_i
      y = (world_mouse.y / Scale::CIRCUIT).to_i

      clicked = App.circuit.components.find do |c|
        c.abs_data?(x, y)
      end

      clicked
    end

    # Handle which input got clicked, and if it should turn on or off.
    def self.handle_io
      if R.mouse_button_released?(INTERACT)
        clicked_io = get_component

        if clicked_io.is_a?(WC::InputToggleOn | WC::InputToggleOff)
          clicked_io.as(Wireland::IO).toggle
        elsif !App.play? && clicked_io.is_a?(WC::InputOn | WC::InputOff)
          clicked_io.as(Wireland::IO).toggle
        end
      end

      if App.play? && R.mouse_button_down?(INTERACT)
        clicked_io = get_component

        if clicked_io.is_a?(WC::InputOn | WC::InputOff)
          clicked_io.as(Wireland::IO).down
        end
      end
    end

    # Handles how the mouse moves the camera
    def self.handle_camera
      camera = App.camera
      # Do the zoom stuff for MWheel
      mouse_wheel = R.get_mouse_wheel_move * Screen::Zoom::UNIT
      if !mouse_wheel.zero?
        camera.zoom = camera.zoom + mouse_wheel

        if camera.zoom < Screen::Zoom::LIMIT_LOWER
          camera.zoom = Screen::Zoom::LIMIT_LOWER
        elsif camera.zoom > Screen::Zoom::LIMIT_UPPER
          camera.zoom = Screen::Zoom::LIMIT_UPPER
        end
      end

      world_mouse = R.get_screen_to_world_2d(@@position, App.camera)

      # Handle panning
      if R.mouse_button_pressed?(CAMERA)
        @@previous_camera_mouse_drag_pos = @@position
      elsif R.mouse_button_down?(Mouse::CAMERA)
        camera.target = camera.target - ((@@position - @@previous_camera_mouse_drag_pos) * 1/camera.zoom)

        @@previous_camera_mouse_drag_pos = @@position
      elsif R.mouse_button_released?(Mouse::CAMERA)
        @@previous_camera_mouse_drag_pos.x = 0
        @@previous_camera_mouse_drag_pos.y = 0
      end

      App.camera = camera
    end

    def self.load
      @@cursor_texture = R.load_texture(CURSOR_TEXTURE_FILE)
      @@small_cursor_texture = R.load_texture(SMALL_CURSOR_TEXTURE_FILE)
      @@selector_texture = R.load_texture(SELECTOR_TEXTURE_FILE)
      setup
    end

    def self.setup
      R.hide_cursor

      image = R.load_image_from_texture(@@cursor_texture)

      # Replace the color black with transparency
      R.image_color_replace(pointerof(image), R::WHITE, App.palette.wire)
      R.image_color_replace(pointerof(image), R::BLACK, App.palette.bg)

      R.unload_texture(@@cursor_texture)
      @@cursor_texture = R.load_texture_from_image(image)
      R.unload_image(image)

      image = R.load_image_from_texture(@@selector_texture)

      # Replace the color black with transparency
      R.image_color_replace(pointerof(image), R::WHITE, App.palette.wire)
      R.image_color_replace(pointerof(image), R::BLACK, App.palette.bg)

      R.unload_texture(@@selector_texture)
      @@selector_texture = R.load_texture_from_image(image)
      R.unload_image(image)
    end

    def self.draw
      src = R::Rectangle.new(
        x: 0,
        y: 0,
        width: @@cursor_texture.width,
        height: @@cursor_texture.height
      )

      dst = R::Rectangle.new(
        x: Mouse.position.x - (@@cursor_texture.width/2) * SCALE,
        y: Mouse.position.y - (@@cursor_texture.height/2) * SCALE,
        width: @@cursor_texture.width * SCALE,
        height: @@cursor_texture.height * SCALE
      )

      if App.camera.zoom > SMALL_CURSOR_ZOOM_LIMIT
        R.draw_texture_pro(@@small_cursor_texture, src, dst, V2.zero, 0, R::WHITE)
      else
        R.draw_texture_pro(@@cursor_texture, src, dst, V2.zero, 0, R::WHITE)
      end
    end

    def self.draw_selector
      world_mouse = R.get_screen_to_world_2d(Mouse.position, App.camera)
      offset = App.circuit_texture.width/2.0
      x = (world_mouse.x / Scale::CIRCUIT).to_i
      y = (world_mouse.y / Scale::CIRCUIT).to_i

      src = R::Rectangle.new(
        x: 0,
        y: 0,
        width: @@selector_texture.width,
        height: @@selector_texture.height
      )

      dst = R::Rectangle.new(
        x: x * Scale::CIRCUIT,
        y: y * Scale::CIRCUIT,
        width: Scale::CIRCUIT,
        height: Scale::CIRCUIT
      )

      if App.camera.zoom > SMALL_CURSOR_ZOOM_LIMIT
        R.draw_texture_pro(@@selector_texture, src, dst, V2.zero, 0, R::WHITE)
      end
    end

    def self.unload
      R.unload_texture(@@cursor_texture)
      R.unload_texture(@@small_cursor_texture)
      R.unload_texture(@@selector_texture)
    end
  end

  module Colors
    HIGH                     = R::GREEN
    WILL_LOSE_ACTIVE_PULSE   = R::RED
    WILL_ACTIVE_PULSE        = R::SKYBLUE
    IS_AND_WILL_ACTIVE_PULSE = R::MAGENTA
  end

  module Help
    TITLE = "Help!"
    TEXT  = %[
    Space - Tick
    Enter - Play, Up - Faster, Down - Slower
    R - Reset
    Left Click - Interact
    Right Click - Info
    Middle Mouse - Pan
    Mouse Wheel - Zoom
    Q - Show Pulses
    W - Solid Pulses].sub("\n", "").gsub("\r", "")

    def self.draw
      if show? && !Info.show?
        App.draw_box(Help::TITLE, Help::TEXT)
      end
    end

    @@show = false

    def self.show?
      @@show
    end

    def self.show
      @@show = true
    end

    def self.hide
      @@show = false
    end

    def self.toggle
      @@show = !@@show
    end
  end

  module Info
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

  # The palette used by Wireland.
  class_getter palette : Wireland::Palette = W::Palette::DEFAULT
  # The circuit object that contains all the stuff for running the simulation.
  class_getter circuit = W::Circuit.new

  # The texture file of the circuit.
  class_getter circuit_texture = R::Texture.new

  @@logo_texture = R::Texture.new

  @@tick_texture = R::Texture.new
  @@play_texture = R::Texture.new

  class_property camera : R::Camera2D = R::Camera2D.new
  @@camera.zoom = Screen::Zoom::DEFAULT
  @@camera.offset.x = Screen::WIDTH/2
  @@camera.offset.y = Screen::HEIGHT/2

  class_property? show_pulses = false
  class_property? solid_pulses = false

  class_property? play = false
  class_property play_time = 0.0
  class_property play_speed = 6
  class_property play_speeds = [0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
  class_getter last_active_pulses = [] of UInt64
  class_getter last_pulses = [] of UInt64

  # Resets the simulation
  def self.reset
    Info.reset
    @@circuit.reset
    @@circuit.pulse_inputs

    @@last_active_pulses.clear
    @@last_pulses.clear
    # @@camera.zoom = Screen::Zoom::DEFAULT
  end

  # Checks to see if the circuit texture is loaded.
  def self.is_circuit_loaded?
    !(@@circuit_texture.width == 0 && @@circuit_texture.height == 0)
  end

  # Loads the circuit from a file
  def self.load_circuit_file(file)
    puts "Loading circuit from #{file}"
    @@circuit = W::Circuit.new(file, @@palette)
    puts "Loaded circuit from #{file}"
    R.unload_texture(@@circuit_texture) if is_circuit_loaded?
    @@circuit_texture = R.load_texture(file)

    puts "Resetting circuit"
    reset
  end

  # Handles when files are dropped into the window, specifically .pal and .png files.
  def self.handle_dropped_files
    if R.file_dropped?
      draw_loading
      dropped_files = R.load_dropped_files
      # Go through all the files dropped
      files = [] of String
      dropped_files.count.times do |i|
        files << String.new dropped_files.paths[i]
      end
      # Unload the files afterwards
      R.unload_dropped_files(dropped_files)

      # Find the first palette file
      if palette_file = files.find { |f| /\.pal$/ =~ f }
        load_palette(palette_file)
      end

      # Find the first png file
      if circuit_file = files.find { |f| /\.png$/ =~ f }
        load_circuit(circuit_file)
      end
    end
  end

  def self.load_palette(palette_file)
    new_palette = W::Palette.new(palette_file)

    image = R.load_image_from_texture(@@logo_texture)

    # Replace the color black with transparency
    R.image_color_replace(pointerof(image), @@palette.start, new_palette.start)
    R.image_color_replace(pointerof(image), @@palette.buffer, new_palette.buffer)
    R.image_color_replace(pointerof(image), @@palette.wire, new_palette.wire)
    R.image_color_replace(pointerof(image), @@palette.alt_wire, new_palette.alt_wire)
    R.image_color_replace(pointerof(image), @@palette.join, new_palette.join)
    R.image_color_replace(pointerof(image), @@palette.cross, new_palette.cross)
    R.image_color_replace(pointerof(image), @@palette.tunnel, new_palette.tunnel)
    R.image_color_replace(pointerof(image), @@palette.input_on, new_palette.input_on)
    R.image_color_replace(pointerof(image), @@palette.input_off, new_palette.input_off)
    R.image_color_replace(pointerof(image), @@palette.input_toggle_on, new_palette.input_toggle_on)
    R.image_color_replace(pointerof(image), @@palette.input_toggle_off, new_palette.input_toggle_off)
    R.image_color_replace(pointerof(image), @@palette.output_on, new_palette.output_on)
    R.image_color_replace(pointerof(image), @@palette.output_off, new_palette.output_off)
    R.image_color_replace(pointerof(image), @@palette.not_in, new_palette.not_in)
    R.image_color_replace(pointerof(image), @@palette.not_out, new_palette.not_out)
    R.image_color_replace(pointerof(image), @@palette.switch, new_palette.switch)
    R.image_color_replace(pointerof(image), @@palette.no_pole, new_palette.no_pole)
    R.image_color_replace(pointerof(image), @@palette.nc_pole, new_palette.nc_pole)
    R.image_color_replace(pointerof(image), @@palette.diode_in, new_palette.diode_in)
    R.image_color_replace(pointerof(image), @@palette.diode_out, new_palette.diode_out)
    R.image_color_replace(pointerof(image), @@palette.gpio, new_palette.gpio)
    R.image_color_replace(pointerof(image), @@palette.bg, new_palette.bg)

    # R.image_flip_vertical(pointerof(image))
    # Reload the texture from the image
    R.unload_texture(@@logo_texture)
    @@logo_texture = R.load_texture_from_image(image)

    # Clean up the old data
    R.unload_image(image)

    @@palette = new_palette
    Mouse.setup
  end

  def self.load_circuit(circuit_file)
    # Load the file into texture memory.
    @@camera.zoom = Screen::Zoom::DEFAULT

    start_time = R.get_time
    load_circuit_file(circuit_file)
    @@camera.target.x = @@circuit_texture.width/2 * Scale::CIRCUIT
    @@camera.target.y = @@circuit_texture.width/2 * Scale::CIRCUIT
    puts "Total time: #{R.get_time - start_time}"
  end

  # Move the circuit forward a tick
  def self.tick
    @@circuit.increase_ticks
    @@circuit.pulse_inputs
    @@circuit.pre_tick

    @@last_active_pulses = @@circuit.active_pulses.keys

    @@circuit.mid_tick
    @@last_pulses = @@circuit.components.select(&.high?).map(&.id)

    @@circuit.post_tick
    @@tick_hold_time = R.get_time
    @@tick_long_hold_time = R.get_time
  end

  # Draw the circuit texture
  def self.draw_circuit
    R.draw_texture_ex(@@circuit_texture, V2.zero, 0, Scale::CIRCUIT, R::WHITE)
  end

  # Draw the component textures, such as if the component is conductive, or if the component is pulsed, pulsing, was pulsing, will pulse, etc.
  def self.draw_components
    @@circuit.components.each do |c|
      if (@@show_pulses && (
           @@last_pulses.includes?(c.id) ||
           @@last_active_pulses.includes?(c.id) ||
           @@circuit.active_pulses.keys.includes?(c.id)
         ) ||
         c.is_a?(Wireland::RelayPole) ||
         c.is_a?(Wireland::IO)
           )
        color = R::Color.new

        if @@circuit.active_pulses.keys.includes?(c.id) && @@last_active_pulses.includes?(c.id)
          color = Colors::IS_AND_WILL_ACTIVE_PULSE
        elsif @@last_active_pulses.includes?(c.id)
          color = Colors::WILL_LOSE_ACTIVE_PULSE
        elsif @@circuit.active_pulses.keys.includes?(c.id)
          color = Colors::WILL_ACTIVE_PULSE
        elsif @@last_pulses.includes? c.id
          color = Colors::HIGH
        end

        if c.is_a?(Wireland::IO | Wireland::RelayPole)
          special_color = R::Color.new
          if c.is_a?(WC::InputOff | WC::InputOn | WC::InputToggleOff | WC::InputToggleOn)
            io = c.as(Wireland::IO)
            special_color = io.color

            if io.on? && @@last_active_pulses.includes?(c.id)
              color = Colors::IS_AND_WILL_ACTIVE_PULSE
            elsif io.on?
              color = Colors::WILL_ACTIVE_PULSE
            elsif io.off? && (@@last_active_pulses.includes?(c.id) || @@circuit.active_pulses.keys.includes?(c.id))
              color = Colors::WILL_LOSE_ACTIVE_PULSE
            end
          elsif c.is_a?(Wireland::IO)
            io = c.as(Wireland::IO)
            special_color = io.color
          end

          c.points.each do |xy|
            R.draw_rectangle_rec(
              R::Rectangle.new(
                x: (xy[:x] * Scale::CIRCUIT),
                y: (xy[:y] * Scale::CIRCUIT),
                width: Scale::CIRCUIT,
                height: Scale::CIRCUIT
              ),
              special_color
            )
          end

          if c.is_a?(Wireland::RelayPole) && !c.conductive?
            margin = 0.1
            c.points.each do |xy|
              R.draw_rectangle_rec(
                R::Rectangle.new(
                  x: (xy[:x] * Scale::CIRCUIT) + (margin * Scale::CIRCUIT),
                  y: (xy[:y] * Scale::CIRCUIT) + (margin * Scale::CIRCUIT),
                  width: Scale::CIRCUIT - (margin * Scale::CIRCUIT * 2),
                  height: Scale::CIRCUIT - (margin * Scale::CIRCUIT * 2)
                ),
                @@palette.bg
              )
            end
          end
        end
        if @@show_pulses && !@@solid_pulses && @@camera.zoom > 1.0
          margin = 0.3
          c.points.each do |xy|
            R.draw_rectangle_rec(
              R::Rectangle.new(
                x: (xy[:x] * Scale::CIRCUIT) + (margin * Scale::CIRCUIT),
                y: (xy[:y] * Scale::CIRCUIT) + (margin * Scale::CIRCUIT),
                width: Scale::CIRCUIT - (margin * Scale::CIRCUIT * 2),
                height: Scale::CIRCUIT - (margin * Scale::CIRCUIT * 2)
              ),
              color
            )
          end
        elsif @@show_pulses
          c.points.each do |xy|
            R.draw_rectangle_rec(
              R::Rectangle.new(
                x: (xy[:x] * Scale::CIRCUIT),
                y: (xy[:y] * Scale::CIRCUIT),
                width: Scale::CIRCUIT,
                height: Scale::CIRCUIT
              ),
              color
            )
          end
        end
      end
    end
  end

  def self.draw_box(title : String, text : String)
    max_text_size = 30
    width = Screen::WIDTH/2
    height = Screen::HEIGHT/2

    rect = {
      x:      width/2,
      y:      height/2,
      width:  width,
      height: height,
    }

    R.draw_rectangle(
      rect[:x],
      rect[:y],
      width,
      height,
      @@palette.wire
    )

    center_x = Screen::WIDTH/2

    title_size = 60
    text_size = max_text_size

    offset = title_size + 20

    text_length = R.measure_text(title, title_size)
    R.draw_text(
      title,
      center_x - text_length/2,
      rect[:y] + 10,
      title_size,
      @@palette.bg
    )

    text_bounds = R.measure_text_ex(R.get_font_default, text, max_text_size, 1.0)
    until text_bounds.y < rect[:height] - offset
      text_size -= 1
      text_bounds = R.measure_text_ex(R.get_font_default, text, text_size, 1.0)
    end

    R.draw_text_ex(
      R.get_font_default,
      text,
      V2.new(x: rect[:x] + 30, y: rect[:y] + offset),
      text_size,
      1.0,
      @@palette.bg
    )
  end

  def self.draw_loading
    text = "Loading"
    text_size = 60
    text_length = R.measure_text(text, text_size)

    R.begin_drawing
    R.clear_background(@@palette.bg)
    R.draw_text(text, Screen::WIDTH/2 - text_length/2, Screen::HEIGHT/2 - text_size/2, text_size, @@palette.wire)
    R.end_drawing
  end

  def self.draw_debug_hud
    R.draw_text(R.get_fps.to_s, Screen::WIDTH - 50, 10, 40, R::MAGENTA)
    R.draw_text(@@camera.zoom.to_s, Screen::WIDTH - 50, 55, 40, R::GREEN)
  end

  def self.draw_ticks_counter
    scale_w = 0.12
    scale_h = 0.07
    margin_x = 0.05
    margin_y = 0.1

    width = Screen::WIDTH * scale_w
    height = Screen::HEIGHT * scale_h
    x = Screen::WIDTH - width
    y = Screen::HEIGHT - height

    i_width = width - width*margin_x
    i_height = height - height*margin_y
    i_margin_x = ((width - i_width)/2)
    i_margin_y = ((height - i_height)/2)

    i_x = x + i_margin_x
    i_y = y + i_margin_y

    text = (@@circuit.ticks).to_s
    text_size = i_height - i_height*margin_y
    text_length = R.measure_text(text, text_size)

    text_x = i_x + i_width - text_length - i_margin_x*3
    text_y = i_y + i_margin_y

    icon_dst = R::Rectangle.new(
      x: i_x + i_margin_x,
      y: i_y + i_margin_y,
      width: text_size,
      height: text_size
    )

    if (text_length + text_size) > i_width
      i_width = text_length + text_size + i_width*margin_x
      width = i_width + i_width*margin_x
      x = Screen::WIDTH - width
      i_x = x + i_margin_x
      clock_dst = R::Rectangle.new(
        x: text_x - text_size,
        y: text_y,
        width: text_size,
        height: text_size
      )
    end

    R.draw_rectangle(x, y, width, height, @@palette.wire)
    R.draw_rectangle_lines(i_x, i_y, i_width, i_height, @@palette.bg)
    R.draw_text(text, text_x, text_y, text_size, @@palette.bg)
    if @@play
      icon_src = R::Rectangle.new(
        x: 0,
        y: 0,
        width: @@play_texture.width,
        height: @@play_texture.height
      )
      R.draw_texture_pro(@@play_texture, icon_src, icon_dst, V2.zero, 0, R::WHITE)
      small_text_size = text_size/8

      R.draw_text("X#{@@play_speeds[@@play_speed].to_s[0..4]}", icon_dst.x + text_size*0.1, icon_dst.y + text_size/2 - small_text_size/2, small_text_size, @@palette.wire)
    else
      icon_src = R::Rectangle.new(
        x: 0,
        y: 0,
        width: @@tick_texture.width,
        height: @@tick_texture.height
      )
      R.draw_texture_pro(@@tick_texture, icon_src, icon_dst, V2.zero, 0, R::WHITE)
    end
  end

  def self.draw_menu
    fade = Math.sin(R.get_time*10).abs.clamp(0.3, 1.0)
    text = "Drop a .pal or .png to begin!"
    text_size = 40
    text_length = R.measure_text(text, text_size)

    scale = 2
    logo_width = text_length*scale
    logo_height = (@@logo_texture.height/@@logo_texture.width) * text_length*scale

    whole_height = logo_height + text_size

    src = R::Rectangle.new(
      x: 0,
      y: 0,
      width: @@logo_texture.width,
      height: @@logo_texture.height
    )

    dst = R::Rectangle.new(
      x: Screen::WIDTH/2 - logo_width/2,
      y: Screen::HEIGHT/2 - whole_height/2,
      width: logo_width,
      height: logo_height
    )
    R.draw_texture_pro(@@logo_texture, src, dst, V2.zero, 0, R::WHITE)
    R.draw_text(text, Screen::WIDTH/2 - text_length/2, dst.y + dst.height, text_size, R.fade(@@palette.wire, fade))
  end

  def self.run
    R.init_window(Screen::WIDTH, Screen::HEIGHT, "wireland")
    R.set_target_fps(60)

    @@logo_texture = R.load_texture("rsrc/sim/logo.png")
    @@tick_texture = R.load_texture("rsrc/sim/clock.png")
    @@play_texture = R.load_texture("rsrc/sim/play.png")

    Mouse.load

    until R.close_window?
      Mouse.update
      handle_dropped_files

      if is_circuit_loaded?
        Keys.update
        Info.update

        if !Info.show? && !Help.show?
          Mouse.handle_camera
          Mouse.handle_io
        end
      end

      R.begin_drawing
      R.clear_background(@@palette.bg)
      if !is_circuit_loaded?
        draw_menu
      end
      R.begin_mode_2d @@camera
      if is_circuit_loaded?
        draw_circuit
        draw_components

        Mouse.draw_selector
      end
      R.end_mode_2d
      if is_circuit_loaded?
        Info.draw
        Help.draw
        draw_ticks_counter
        draw_debug_hud
      end
      Mouse.draw
      R.end_drawing
    end

    R.unload_texture(@@circuit_texture) if is_circuit_loaded?
    R.unload_texture(@@logo_texture)
    R.unload_texture(@@tick_texture)
    R.unload_texture(@@play_texture)

    Mouse.unload
    R.close_window
  end
end

Wireland::App.run
