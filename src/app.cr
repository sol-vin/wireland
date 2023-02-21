require "./wireland"
require "./app/**"

module Wireland::App
  alias W = Wireland

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

  # The palette used by Wireland.
  class_getter palette : W::Palette = W::Palette::DEFAULT
  # The circuit object that contains all the stuff for running the simulation.
  class_getter circuit = W::Circuit.new

  # The texture file of the circuit.
  class_getter circuit_texture = R::Texture.new

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

  class_getter font : R::Font = R::Font.new

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
      Loading.draw
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

    Menu.update_logo(new_palette)

    @@palette = new_palette
    Mouse.setup
  end

  def self.load_circuit(circuit_file)
    # Load the file into texture memory.
    @@camera.zoom = Screen::Zoom::DEFAULT

    start_time = R.get_time
    load_circuit_file(circuit_file)
    @@camera.target.x = @@circuit_texture.width/2 * Scale::CIRCUIT
    @@camera.target.y = @@circuit_texture.height/2 * Scale::CIRCUIT
    puts "Total time: #{R.get_time - start_time}"
  end

  def self.load_font
    @@font = R.load_font_ex("rsrc/sim/font.ttf", 128, Pointer(LibC::Int).null, 0)

    R.set_texture_filter(@@font.texture, R::TextureFilter::Anisotropic16x)
  end

  def self.unload_font
    R.unload_font(@@font)
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
          color = @@palette.is_and_will_active
        elsif @@last_active_pulses.includes?(c.id)
          color = @@palette.is_active
        elsif @@circuit.active_pulses.keys.includes?(c.id)
          color = @@palette.will_active
        elsif @@last_pulses.includes? c.id
          color = @@palette.high
        end

        if c.is_a?(Wireland::IO | Wireland::RelayPole)
          special_color = R::Color.new
          if c.is_a?(Wireland::Component::InputOff | Wireland::Component::InputOn | Wireland::Component::InputToggleOff | Wireland::Component::InputToggleOn)
            io = c.as(Wireland::IO)
            special_color = io.color

            if io.on? && @@last_active_pulses.includes?(c.id)
              color = @@palette.is_and_will_active
            elsif io.on?
              color = @@palette.will_active
            elsif io.off? && (@@last_active_pulses.includes?(c.id) || @@circuit.active_pulses.keys.includes?(c.id))
              color = @@palette.is_active
            end
          elsif c.is_a?(Wireland::IO)
            io = c.as(Wireland::IO)
            special_color = io.color
          end

          c.points.each do |xy|
            margin = 0.01
            R.draw_rectangle_rec(
              R::Rectangle.new(
                x: (xy[:x] * Scale::CIRCUIT) - margin,
                y: (xy[:y] * Scale::CIRCUIT) - margin,
                width: Scale::CIRCUIT + margin * 2,
                height: Scale::CIRCUIT + margin * 2
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
          margin = 0.2
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
            margin = 0.01
            R.draw_rectangle_rec(
              R::Rectangle.new(
                x: (xy[:x] * Scale::CIRCUIT) - margin,
                y: (xy[:y] * Scale::CIRCUIT) - margin,
                width: Scale::CIRCUIT + margin * 2,
                height: Scale::CIRCUIT + margin * 2
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
    R.draw_text_ex(
      @@font,
      title,
      V2.new(
        x: center_x - text_length/2,
        y: rect[:y] + 10
      ),
      title_size,
      0,
      @@palette.bg
    )

    text_bounds = R.measure_text_ex(R.get_font_default, text, max_text_size, 1.0)
    until text_bounds.y < rect[:height] - offset
      text_size -= 1
      text_bounds = R.measure_text_ex(R.get_font_default, text, text_size, 1.0)
    end

    R.draw_text_ex(
      @@font,
      text,
      V2.new(x: rect[:x] + 30, y: rect[:y] + offset),
      text_size,
      1.0,
      @@palette.bg
    )
  end

  def self.draw_debug_hud
    R.draw_text(R.get_fps.to_s, Screen::WIDTH - 50, 10, 40, R::MAGENTA)
    # R.draw_text(@@camera.zoom.to_s, Screen::WIDTH - 50, 55, 40, R::GREEN)
  end

  def self.run
    R.init_window(Screen::WIDTH, Screen::HEIGHT, "wireland")
    R.set_target_fps(60)

    load_font
    TicksCounter.load
    Menu.load
    Mouse.load

    until R.close_window?
      Mouse.update
      handle_dropped_files

      if is_circuit_loaded?
        Info.update

        if !Info.show? && !Help.show?
          Keys.update
          Mouse.handle_camera
          Mouse.handle_io
        end
      end

      R.begin_drawing
      R.clear_background(@@palette.bg)
      if !is_circuit_loaded?
        Menu.draw
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
        TicksCounter.draw
        draw_debug_hud
      end
      Mouse.draw
      R.end_drawing
    end

    R.unload_texture(@@circuit_texture) if is_circuit_loaded?


    TicksCounter.unload
    Menu.unload
    Mouse.unload
    unload_font
    R.close_window
  end
end

Wireland::App.run
