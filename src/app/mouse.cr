module Wireland::App::Mouse
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

      if clicked_io.is_a?(Wireland::Component::InputToggleOn | Wireland::Component::InputToggleOff)
        clicked_io.as(Wireland::IO).toggle
      elsif !App.play? && clicked_io.is_a?(Wireland::Component::InputOn | Wireland::Component::InputOff)
        clicked_io.as(Wireland::IO).toggle
      end
    end

    if App.play? && R.mouse_button_down?(INTERACT)
      clicked_io = get_component

      if clicked_io.is_a?(Wireland::Component::InputOn | Wireland::Component::InputOff)
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