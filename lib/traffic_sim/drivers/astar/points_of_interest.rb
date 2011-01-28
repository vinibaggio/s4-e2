module TrafficSim
  module Drivers
    class AStar
      class PointsOfInterest
        attr_reader :vehicle_position, :dock_position

        def initialize(map, driver_name)
          number_of_cols = map.columns.length
          number_of_rows = map.rows.length
          my_position    = []
          dock_position  = []

          (0...number_of_rows).each do |i|
            (0...number_of_cols).each do |j|
              @vehicle_position = [i,j] if map.vehicle_for?([i,j], driver_name)
              @dock_position    = [i,j] if map.dock_for?([i,j], driver_name)
            end
          end
        end
      end
    end
  end
end
