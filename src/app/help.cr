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
      App.draw_box((Screen::WIDTH/2).to_i, (Screen::HEIGHT/2).to_i, Help::TITLE, Help::TEXT)
    end
  end

  def self.update
    hide if Keys::ALL.any? {|k| R.key_released?(k) } || Mouse::ALL.any? { |m| R.mouse_button_released?(m) }
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
