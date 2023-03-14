module Wireland::App::Assets::Textures
  class_getter logo = R::Texture.new

  class_getter tick = R::Texture.new
  class_getter play = R::Texture.new

  class_getter cursor = R::Texture.new
  class_getter small_cursor = R::Texture.new
  class_getter selector = R::Texture.new

  @@previous_camera_mouse_drag_pos = V2.zero

  PLAY_FILE         = "rsrc/sim/play.png"
  CLOCK_FILE        = "rsrc/sim/clock.png"
  CURSOR_FILE       = "rsrc/sim/cursor.png"
  SMALL_CURSOR_FILE = "rsrc/sim/smallcursor.png"
  SELECTOR_FILE     = "rsrc/sim/selector.png"

  def self.load
    @@logo = R.load_texture("rsrc/sim/logo.png")

    @@tick = R.load_texture(CLOCK_FILE)
    @@play = R.load_texture(PLAY_FILE)

    @@cursor = R.load_texture(CURSOR_FILE)
    @@small_cursor = R.load_texture(SMALL_CURSOR_FILE)
    @@selector = R.load_texture(SELECTOR_FILE)
  end

  def self.unload
    R.unload_texture(@@logo)
    R.unload_texture(@@tick)
    R.unload_texture(@@play)
    R.unload_texture(@@cursor)
    R.unload_texture(@@small_cursor)
    R.unload_texture(@@selector)
  end

  def self.update_cursor
    image = R.load_image_from_texture(@@cursor)

    # Replace the color black with transparency
    R.image_color_replace(pointerof(image), R::WHITE, App.palette.wire)
    R.image_color_replace(pointerof(image), R::BLACK, App.palette.bg)

    R.unload_texture(@@cursor)
    @@cursor = R.load_texture_from_image(image)
    R.unload_image(image)

    image = R.load_image_from_texture(@@selector)

    # Replace the color black with transparency
    R.image_color_replace(pointerof(image), R::WHITE, App.palette.wire)
    R.image_color_replace(pointerof(image), R::BLACK, App.palette.bg)

    R.unload_texture(@@selector)
    @@selector = R.load_texture_from_image(image)
    R.unload_image(image)
  end

  def self.update_logo(new_palette)
    image = R.load_image_from_texture(@@logo)

    # Replace the color black with transparency
    R.image_color_replace(pointerof(image), App.palette.start, new_palette.start)
    R.image_color_replace(pointerof(image), App.palette.buffer, new_palette.buffer)
    R.image_color_replace(pointerof(image), App.palette.wire, new_palette.wire)
    R.image_color_replace(pointerof(image), App.palette.alt_wire, new_palette.alt_wire)
    R.image_color_replace(pointerof(image), App.palette.join, new_palette.join)
    R.image_color_replace(pointerof(image), App.palette.cross, new_palette.cross)
    R.image_color_replace(pointerof(image), App.palette.tunnel, new_palette.tunnel)
    R.image_color_replace(pointerof(image), App.palette.input_on, new_palette.input_on)
    R.image_color_replace(pointerof(image), App.palette.input_off, new_palette.input_off)
    R.image_color_replace(pointerof(image), App.palette.input_toggle_on, new_palette.input_toggle_on)
    R.image_color_replace(pointerof(image), App.palette.input_toggle_off, new_palette.input_toggle_off)
    R.image_color_replace(pointerof(image), App.palette.output_on, new_palette.output_on)
    R.image_color_replace(pointerof(image), App.palette.output_off, new_palette.output_off)
    R.image_color_replace(pointerof(image), App.palette.not_in, new_palette.not_in)
    R.image_color_replace(pointerof(image), App.palette.not_out, new_palette.not_out)
    R.image_color_replace(pointerof(image), App.palette.switch, new_palette.switch)
    R.image_color_replace(pointerof(image), App.palette.no_pole, new_palette.no_pole)
    R.image_color_replace(pointerof(image), App.palette.nc_pole, new_palette.nc_pole)
    R.image_color_replace(pointerof(image), App.palette.diode_in, new_palette.diode_in)
    R.image_color_replace(pointerof(image), App.palette.diode_out, new_palette.diode_out)
    R.image_color_replace(pointerof(image), App.palette.gpio, new_palette.gpio)
    R.image_color_replace(pointerof(image), App.palette.bg, new_palette.bg)

    # Reload the texture from the image
    R.unload_texture(@@logo)
    @@logo = R.load_texture_from_image(image)

    # Clean up the old data
    R.unload_image(image)
  end
end
