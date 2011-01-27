module TrafficSim
  module Drivers
    class AStar
      module MapTools
        extend self

        def surroundings(origin)
          surroundings = []

          (-1..1).each do |row_offset|
            (-1..1).each do |column_offset|
              map_i = origin[0] + row_offset
              map_j = origin[1] + column_offset

              unless row_offset == 0 && column_offset == 0 # do not include itself
                surroundings << [map_i, map_j]
              end
            end
          end

          surroundings
        end

        def points_of_interest(map, driver_name)
          number_of_cols = map.columns.length
          number_of_rows = map.rows.length
          my_position    = []
          dock_position  = []

          (0...number_of_rows).each do |i|
            (0...number_of_cols).each do |j|
              if map[i,j].is_a?(Vehicle) && map[i, j].driver_name == driver_name
                my_position = [i,j]
              end

              if owned_by?(map[i,j], driver_name)
                dock_position = [i,j]
              end
            end
          end

          {:vehicle_position => my_position, :dock_position => dock_position}
        end

        def owned_by?(map_element, driver_name)
          map_element.is_a?(Dock) && map_element.owned_by?(driver_name)
        end
      end
    end
  end
end

