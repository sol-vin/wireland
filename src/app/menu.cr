module Wireland::App::Menu
  def self.draw
    fade = Math.sin(R.get_time*10).abs.clamp(0.3, 1.0)
    text = "Drop a .pal or .png to begin!"
    text_size = 40
    text_length = R.measure_text(text, text_size)

    scale = 2
    logo_width = text_length*scale
    logo_height = (Assets::Textures.logo.height/Assets::Textures.logo.width) * text_length*scale

    whole_height = logo_height + text_size

    src = R::Rectangle.new(
      x: 0,
      y: 0,
      width: Assets::Textures.logo.width,
      height: Assets::Textures.logo.height
    )

    dst = R::Rectangle.new(
      x: Screen::WIDTH/2 - logo_width/2,
      y: Screen::HEIGHT/2 - whole_height/2,
      width: logo_width,
      height: logo_height
    )
    R.draw_texture_pro(Assets::Textures.logo, src, dst, V2.zero, 0, R::WHITE)
    R.draw_text(text, Screen::WIDTH/2 - text_length/2, dst.y + dst.height, text_size, R.fade(App.palette.wire, fade))
  end
end
