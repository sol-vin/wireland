module Wireland::App::TicksCounter
  SCALE_W = 0.12
  SCALE_H = 0.07
  MARGIN_X = 0.05
  MARGIN_Y = 0.05

  def self.draw
    width = Screen::WIDTH * SCALE_W
    height = Screen::HEIGHT * SCALE_H
    x = Screen::WIDTH - width
    y = Screen::HEIGHT - height

    i_width = width - width*MARGIN_X
    i_height = height - height*MARGIN_Y
    i_margin_x = ((width - i_width)/2)
    i_margin_y = ((height - i_height)/2)

    i_x = x + i_margin_x
    i_y = y + i_margin_y

    text = (App.circuit.ticks).to_s
    text_size = i_height - i_height*MARGIN_Y
    text_length = R.measure_text(text, text_size)

    text_x = i_x + i_width - text_length - i_margin_x*3
    text_y = i_y + i_margin_y

    icon_dst = R::Rectangle.new(
      x: i_x + i_margin_x,
      y: i_y + i_margin_y,
      width: text_size - i_margin_y,
      height: text_size - i_margin_x
    )

    if (text_length + text_size) > i_width - text_size
      i_width = text_length + text_size + i_width*MARGIN_X + 20
      width = i_width + i_width*MARGIN_X
      x = Screen::WIDTH - width
      i_x = x + i_margin_x
      icon_dst = R::Rectangle.new(
        x: text_x - text_size - 10,
        y: text_y,
        width: text_size,
        height: text_size
      )
    end

    R.draw_rectangle(x, y, width, height, App.palette.wire)
    R.draw_rectangle_lines(i_x, i_y, i_width, i_height, App.palette.bg)
    R.draw_text(text, text_x, text_y, text_size, App.palette.bg)
    if App.play?
      icon_src = R::Rectangle.new(
        x: 0,
        y: 0,
        width: Assets::Textures.play.width,
        height: Assets::Textures.play.height
      )
      R.draw_texture_pro(Assets::Textures.play, icon_src, icon_dst, V2.zero, 0, App.palette.bg)
      small_text_size = text_size/8

      R.draw_text("X#{App.play_speeds[App.play_speed].to_s[0..4]}", icon_dst.x + text_size*0.1, icon_dst.y + text_size/2 - small_text_size/2, small_text_size, App.palette.wire)
    else
      icon_src = R::Rectangle.new(
        x: 0,
        y: 0,
        width: Assets::Textures.tick.width,
        height: Assets::Textures.tick.height
      )
      R.draw_texture_pro(Assets::Textures.tick, icon_src, icon_dst, V2.zero, 0, App.palette.bg)
    end
  end
end
