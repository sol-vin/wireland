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
      LIMIT_UPPER = 8.0_f32
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
  end

  module Mouse
    CAMERA   = R::MouseButton::Middle
    INTERACT = R::MouseButton::Left
    INFO     = R::MouseButton::Right
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
    Enter - Play
    R - Reset
    Left Click - Interact
    Right Click - Info
    Middle Mouse - Pan
    Mouse Wheel - Zoom
    Q - Show Pulses
    W - Solid Pulses].sub("\n", "").gsub("\r", "")
  end

  # The palette used by Wireland.
  @@palette = W::Palette::DEFAULT
  # The circuit object that contains all the stuff for running the simulation.
  @@circuit = W::Circuit.new
  # The texture file of the circuit.
  @@circuit_texture = R::Texture.new

  @@logo_texture = R::Texture.new

  @@tick_texture = R::Texture.new
  @@play_texture = R::Texture.new

  @@camera = R::Camera2D.new
  @@camera.zoom = Screen::Zoom::DEFAULT
  @@camera.offset.x = Screen::WIDTH/2
  @@camera.offset.y = Screen::HEIGHT/2

  @@previous_camera_mouse_drag_pos = V2.zero

  @@show_help = false
  @@show_pulses = false
  @@solid_pulses = false
  @@play = false
  @@play_time = 0.0
  @@play_speed = 6
  @@play_speeds = [0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

  @@info_id : UInt64? = nil

  @@tick_hold_time = 0.0
  @@tick_long_hold_time = 0.0
  @@tick_long_hold = false

  @@last_active_pulses = [] of UInt64
  @@last_pulses = [] of UInt64

  # Resets the simulation
  def self.reset
    @@info_id = nil
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
  def self.load_circuit(file)
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
      end

      # Find the first png file
      if circuit_file = files.find { |f| /\.png$/ =~ f }
        # Load the file into texture memory.
        @@camera.zoom = Screen::Zoom::DEFAULT

        start_time = R.get_time
        load_circuit(circuit_file)
        @@camera.target.x = @@circuit.width*1.5
        @@camera.target.y = @@circuit.height*1.5
        puts "Total time: #{R.get_time - start_time}"
      end
    end
  end

  # Handles how the mouse moves the camera
  def self.handle_camera_mouse
    # Do the zoom stuff for MWheel
    mouse_wheel = R.get_mouse_wheel_move * Screen::Zoom::UNIT
    if !mouse_wheel.zero?
      new_zoom = @@camera.zoom + mouse_wheel
      @@camera.zoom = new_zoom

      if @@camera.zoom < Screen::Zoom::LIMIT_LOWER
        @@camera.zoom = Screen::Zoom::LIMIT_LOWER
      elsif @@camera.zoom > Screen::Zoom::LIMIT_UPPER
        @@camera.zoom = Screen::Zoom::LIMIT_UPPER
      end
    end

    # Translate cursor coords
    screen_mouse = V2.new
    screen_mouse.x = R.get_mouse_x
    screen_mouse.y = R.get_mouse_y

    world_mouse = R.get_screen_to_world_2d(screen_mouse, @@camera)

    # HAndle panning
    if R.mouse_button_pressed?(Mouse::CAMERA)
      @@previous_camera_mouse_drag_pos = screen_mouse
    elsif R.mouse_button_down?(Mouse::CAMERA)
      @@camera.target = @@camera.target - ((screen_mouse - @@previous_camera_mouse_drag_pos) * 1/@@camera.zoom)

      @@previous_camera_mouse_drag_pos = screen_mouse
    elsif R.mouse_button_released?(Mouse::CAMERA)
      @@previous_camera_mouse_drag_pos.x = 0
      @@previous_camera_mouse_drag_pos.y = 0
    end
  end

  # When a component is right clicked, display a box.
  def self.handle_info
    if @@info_id.nil? && R.mouse_button_released?(Mouse::INFO) && !@@show_help
      screen_mouse = V2.new
      screen_mouse.x = R.get_mouse_x
      screen_mouse.y = R.get_mouse_y

      world_mouse = R.get_screen_to_world_2d(screen_mouse, @@camera)

      # Find which one got clicked
      clicked = @@circuit.components.find do |c|
        # TODO: REWRITE THIS BETTER! Should check bounds before checking points
        c.points.any? do |xy|
          min_xy = {x: xy[:x] * Scale::CIRCUIT - @@circuit_texture.width/2, y: xy[:y] * Scale::CIRCUIT - @@circuit_texture.height/2}
          max_xy = {x: xy[:x] * Scale::CIRCUIT + Scale::CIRCUIT - @@circuit_texture.width/2, y: xy[:y] * Scale::CIRCUIT + Scale::CIRCUIT - @@circuit_texture.height/2}

          world_mouse.x > min_xy[:x] &&
            world_mouse.y > min_xy[:y] &&
            world_mouse.x < max_xy[:x] &&
            world_mouse.y < max_xy[:y]
        end
      end

      # Set it
      if clicked
        @@info_id = clicked.id
      end
      # If any button gets clicked, close the info window
    elsif [Mouse::CAMERA, Mouse::INTERACT, Mouse::INFO].any? { |mb| R.mouse_button_released?(mb) }
      @@info_id = nil
    end
  end

  # Handles what keys do when pressed.
  def self.handle_keys
    if is_circuit_loaded?
      if R.key_released?(Keys::HELP) && !@@info_id
        @@show_help = !@@show_help
      end

      if !@@show_help
        if R.key_released?(Keys::PULSES)
          @@show_pulses = !@@show_pulses
        end

        if R.key_released?(Keys::SOLID_PULSES)
          @@solid_pulses = !@@solid_pulses
        end

        if R.key_released?(Keys::PLAY) && R.key_up?(Keys::TICK)
          @@play = !@@play
          @@play_time = R.get_time
        end

        # Tick when play is enabled
        if @@play && ((R.get_time - @@play_time) > @@play_speeds[@@play_speed])
          tick
          @@play_time = R.get_time
        end

        # Handle spacebar tick. When held down play
        if !@@play
          if R.key_pressed?(Keys::TICK)
            @@tick_hold_time = R.get_time
          end

          if R.key_down?(Keys::TICK) && (R.get_time - @@tick_hold_time) > 1.0 && !@@tick_long_hold
            @@tick_long_hold_time = R.get_time
            @@tick_long_hold = true
          end

          if (R.key_released?(Keys::TICK) && !@@tick_long_hold) || (R.key_down?(Keys::TICK) && @@tick_long_hold && (R.get_time - @@tick_long_hold_time) > 0.1)
            tick
          elsif R.key_up?(Keys::TICK) && @@tick_long_hold
            @@tick_long_hold = false
          end
        end

        if R.key_released?(Keys::RESET)
          reset
        end

        if R.key_released?(R::KeyboardKey::Up)
          @@play_speed -= 1
          @@play_speed = 0 if @@play_speed < 0
        elsif R.key_released?(R::KeyboardKey::Down)
          @@play_speed += 1
          @@play_speed = @@play_speeds.size - 1 if @@play_speed >= @@play_speeds.size
        end
      end
    end
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

  # Handle which input got clicked, and if it should turn on or off.
  def self.handle_io_mouse
    if R.mouse_button_released?(Mouse::INTERACT) && !@@show_help && !@@info_id
      screen_mouse = V2.new
      screen_mouse.x = R.get_mouse_x
      screen_mouse.y = R.get_mouse_y

      world_mouse = R.get_screen_to_world_2d(screen_mouse, @@camera)
      offset = @@circuit_texture.width/2.0
      x = ((world_mouse.x + offset) / Scale::CIRCUIT).to_i
      y = ((world_mouse.y + offset) / Scale::CIRCUIT).to_i - 6
      puts [x, y]

      clicked_io = @@circuit.components.select(&.is_a?(WC::InputOn | WC::InputOff | WC::InputToggleOn | WC::InputToggleOff)).find do |io|
        io.abs_data?(x, y)
      end

      if clicked_io
        clicked_io.as(Wireland::IO).toggle
      end

    end
  end

  # Draw the circuit texture
  def self.draw_circuit
    R.draw_texture_ex(@@circuit_texture, V2.new(x: -@@circuit_texture.width/2, y: -@@circuit_texture.height/2), 0, Scale::CIRCUIT, R::WHITE)
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
                x: (xy[:x] * Scale::CIRCUIT) - (@@circuit_texture.width / 2.0),
                y: (xy[:y] * Scale::CIRCUIT) - (@@circuit_texture.height / 2.0),
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
                  x: (xy[:x] * Scale::CIRCUIT) + (margin * Scale::CIRCUIT) - (@@circuit_texture.width / 2.0),
                  y: (xy[:y] * Scale::CIRCUIT) + (margin * Scale::CIRCUIT) - (@@circuit_texture.height / 2.0),
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
                x: (xy[:x] * Scale::CIRCUIT) + (margin * Scale::CIRCUIT) - (@@circuit_texture.width / 2.0),
                y: (xy[:y] * Scale::CIRCUIT) + (margin * Scale::CIRCUIT) - (@@circuit_texture.height / 2.0),
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
                x: (xy[:x] * Scale::CIRCUIT) - (@@circuit_texture.width / 2.0),
                y: (xy[:y] * Scale::CIRCUIT) - (@@circuit_texture.height / 2.0),
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

  # Draws an info box when info_id is valid
  def self.draw_info
    if (info_id = @@info_id) && !@@show_help
      text = ""

      text += "ID: #{@@info_id}"
      text += "\nSize: #{@@circuit[info_id].size}"
      text += "\n->: #{@@circuit[info_id].connects.size} - #{@@circuit[info_id].connects}"

      if @@circuit[info_id].is_a?(Wireland::IO)
        io = @@circuit[info_id].as(Wireland::IO)
        text += "\nON: #{io.on?}"
      elsif @@circuit[info_id].is_a?(Wireland::RelayPole)
        text += "\nHIGH: #{@@last_pulses.includes? info_id}"
        text += "\nCONDUCTIVE: #{@@circuit[info_id].conductive?}"
      elsif @@circuit[info_id].class.active?
        text += "\nHIGH: #{@@last_pulses.includes? info_id}"
        text += "\nACTIVE: #{@@last_active_pulses.includes?(info_id)}"
        text += "\nWILL ACTIVE: #{@@circuit.active_pulses.keys.includes?(info_id)}"
      else
        text += "\nHIGH: #{@@last_pulses.includes? info_id}"
      end

      draw_box("#{@@circuit[info_id].class.to_s.split("::").last}", text)
    end
  end

  def self.draw_help
    if @@show_help && !@@info_id
      draw_box(Help::TITLE, Help::TEXT)
    end
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
    R.draw_text(R.get_fps.to_s, Screen::WIDTH - 50, 10, 40, @@palette.alt_wire)
    R.draw_text(@@circuit.ticks.to_s, 10, 10, 40, @@palette.wire)
    R.draw_text("#{@@camera.zoom}\n#{@@play_speeds[@@play_speed]}", 10, 60, 40, @@palette.wire)

    # R.draw_text(R.get_fps, 0, 40, 14, @@palette.white)
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
    R.set_target_fps(30)

    @@logo_texture = R.load_texture("rsrc/sim/logo.png")
    @@tick_texture = R.load_texture("rsrc/sim/clock.png")
    @@play_texture = R.load_texture("rsrc/sim/play.png")

    until R.close_window?
      handle_dropped_files

      if is_circuit_loaded?
        if @@info_id.nil? && !@@show_help
          handle_camera_mouse

          handle_io_mouse
        end

        handle_keys
        handle_info
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
      end
      R.end_mode_2d
      if is_circuit_loaded?
        draw_info
        draw_help
        draw_ticks_counter
        # draw_debug_hud
      end
      R.end_drawing
    end

    R.unload_texture(@@circuit_texture) if is_circuit_loaded?
    R.unload_texture(@@logo_texture)
    R.unload_texture(@@tick_texture)
    R.unload_texture(@@play_texture)

    R.close_window
  end
end

Wireland::App.run
