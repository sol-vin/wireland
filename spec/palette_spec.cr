require "./spec_helper"

describe Wireland::Palette do
  it "should be able to read a palette in" do
    palette = Wireland::Palette.new("rsrc/palettes/wireland.pal")
    palette = Wireland::Palette.new("rsrc/palettes/wireland-alt.pal")
  end
end
