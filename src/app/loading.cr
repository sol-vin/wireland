module Wireland::App::Loading
  def self.draw
    text = "Loading"
    text_size = 60
    text_length = R.measure_text(text, text_size)

    R.begin_drawing
    R.clear_background(App.palette.bg)
    R.draw_text(text, Screen::WIDTH/2 - text_length/2, Screen::HEIGHT/2 - text_size/2, text_size, App.palette.wire)
    R.end_drawing
  end
end