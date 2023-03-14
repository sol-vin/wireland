module Wireland::App::Help
  TITLE = "Help!"
  TEXT  = %[
  Space - Tick
  Enter - Play, Up - Faster, Down - Slower
  R - Reset
  Left Click - Interact
  Right Click - Info
  Middle Mouse - Pan
  Mouse Wheel - Zoom
  Q - Show Pulses
  W - Solid Pulses].sub("\n", "").gsub("\r", "")

  def self.draw
    if show? && !Info.show?
      App.draw_box(Help::TITLE, Help::TEXT)
    end
  end

  @@show = false

  def self.show?
    @@show
  end

  def self.show
    @@show = true
  end

  def self.hide
    @@show = false
  end

  def self.toggle
    @@show = !@@show
  end
end
