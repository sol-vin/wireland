require "raylib-cr"
require "./wireland/component"
require "./wireland/circuit"
require "./wireland/**"

module Wireland
  alias R = Raylib
  alias V2 = R::Vector2

  alias Rectangle = NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
  alias Point = NamedTuple(x: Int32, y: Int32)
end
