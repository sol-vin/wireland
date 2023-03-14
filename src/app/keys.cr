module Wireland::App::Keys
  HELP         = R::KeyboardKey::Slash
  PULSES       = R::KeyboardKey::Q
  SOLID_PULSES = R::KeyboardKey::W
  TICK         = R::KeyboardKey::Space
  RESET        = R::KeyboardKey::R
  PLAY         = R::KeyboardKey::Enter

  ALL = [
    HELP,
    PULSES,
    SOLID_PULSES,
    TICK,
    RESET,
    PLAY
  ]

  @@tick_hold_time = 0.0
  @@tick_long_hold_time = 0.0
  @@tick_long_hold = false

  # Handles what keys do when pressed.
  def self.update
    if App.is_circuit_loaded?
      if R.key_released?(Keys::HELP) && !Info.show?
        Help.toggle
      end

      if !Help.show?
        if R.key_released?(Keys::PULSES)
          App.show_pulses = !App.show_pulses?
        end

        if R.key_released?(Keys::SOLID_PULSES)
          App.solid_pulses = !App.solid_pulses?
        end

        if R.key_released?(Keys::PLAY) && R.key_up?(Keys::TICK)
          App.play = !App.play?
          App.play_time = R.get_time
        end

        # Tick when play is enabled
        if App.play? && ((R.get_time - App.play_time) > App.play_speeds[App.play_speed])
          App.tick
          App.play_time = R.get_time
        end

        # Handle spacebar tick. When held down play
        if !App.play?
          if R.key_pressed?(Keys::TICK)
            @@tick_hold_time = R.get_time
          end

          if R.key_down?(Keys::TICK) && (R.get_time - @@tick_hold_time) > 1.0 && !@@tick_long_hold
            @@tick_long_hold_time = R.get_time
            @@tick_long_hold = true
          end

          if (R.key_released?(Keys::TICK) && !@@tick_long_hold) || (R.key_down?(Keys::TICK) && @@tick_long_hold && (R.get_time - @@tick_long_hold_time) > 0.1)
            App.tick
          elsif R.key_up?(Keys::TICK) && @@tick_long_hold
            @@tick_long_hold = false
          end
        end

        if R.key_released?(Keys::RESET)
          App.reset
        end

        if R.key_released?(R::KeyboardKey::Up)
          App.play_speed -= 1
          App.play_speed = 0 if App.play_speed < 0
        elsif R.key_released?(R::KeyboardKey::Down)
          App.play_speed += 1
          App.play_speed = App.play_speeds.size - 1 if App.play_speed >= App.play_speeds.size
        end
      end
    end
  end
end
