module Wireland::App::Assets
  class_getter font : R::Font = R::Font.new

  FONT_FILE = "rsrc/sim/font.ttf"

  def self.load_font
    @@font = R.load_font_ex(FONT_FILE, 128, Pointer(LibC::Int).null, 0)

    R.set_texture_filter(@@font.texture, R::TextureFilter::Anisotropic16x)
  end

  def self.unload_font
    R.unload_font(@@font)
  end
end