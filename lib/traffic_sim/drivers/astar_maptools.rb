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
              my_position   = [i,j] if is_it_me?(map[i,j], driver_name)
              dock_position = [i,j] if owned_by?(map[i,j], driver_name)
            end
          end

          {:vehicle_position => my_position, :dock_position => dock_position}
        end

        def owned_by?(map_element, driver_name)
          map_element.is_a?(Dock) && map_element.owned_by?(driver_name)
        end

        def is_it_me?(map_element, driver_name)
          map_element.is_a?(Vehicle) && map_element.driver_name == driver_name
        end

        def add_vectors(vector_a, vector_b)
          (0..1).map do |idx|
            vector_a[idx] + vector_b[idx]
          end
        end

        def subtract_vectors(vector_a, vector_b)
          (0..1).map do |idx|
            vector_a[idx] - vector_b[idx]
          end
        end
      end
    end
  end
end

