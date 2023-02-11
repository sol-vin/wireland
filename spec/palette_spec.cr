require "./spec_helper"

describe Wireland::Palette do
  it "should be able to read a palette in" do
    palette = Wireland::Palette.new("rsrc/wireland.pal")
    palette = Wireland::Palette.new("rsrc/wireland-alt.pal")
  end
end
