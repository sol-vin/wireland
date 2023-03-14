module Wireland::App::Loader
  # Handles when files are dropped into the window, specifically .pal and .png files.
  def self.update
    if R.file_dropped?
      Loading.draw
      dropped_files = R.load_dropped_files
      # Go through all the files dropped
      files = [] of String
      dropped_files.count.times do |i|
        files << String.new dropped_files.paths[i]
      end
      # Unload the files afterwards
      R.unload_dropped_files(dropped_files)

      # Find the first palette file
      if palette_file = files.find { |f| /\.pal$/ =~ f }
        App.load_palette(palette_file)
      end

      # Find the first png file
      if circuit_file = files.find { |f| /\.png$/ =~ f }
        App.load_circuit(circuit_file)
      end
    end
  end
end
