module Wireland::App::Menu
  class_getter logo_texture = R::Texture.new

  def self.load
    @@logo_texture = R.load_texture("rsrc/sim/logo.png")
  end

  def self.unload
    R.unload_texture(@@logo_texture)
  end

  def self.update_logo(new_palette)
    image = R.load_image_from_texture(@@logo_texture)

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

    # R.image_flip_vertical(pointerof(image))
    # Reload the texture from the image
    R.unload_texture(@@logo_texture)
    @@logo_texture = R.load_texture_from_image(image)

    # Clean up the old data
    R.unload_image(image)
  end

  def self.draw
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
    R.draw_text(text, Screen::WIDTH/2 - text_length/2, dst.y + dst.height, text_size, R.fade(App.palette.wire, fade))
  end
end