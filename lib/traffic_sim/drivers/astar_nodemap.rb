module TrafficSim
  module Drivers
    class AStar
      class NodeMap
        def initialize(map)
          @node_map = {}
          copy_map_elements(map)
        end

        def [](row, column)
          @node_map[row][column]
        end

        def []=(row, column, val)
          raise ArgumentError, 'Must be of type Node' unless val.is_a?(Node)
          @node_map[row][column] = val
        end

        def visited?(position)
          self[*position].visited?
        end

        def mark_as_visited(position)
          self[*position].visited = true
        end

        private
        def copy_map_elements(map)
          number_of_columns = map.columns.length
          number_of_rows    = map.rows.length

          (0...number_of_rows).each do |i|
            (0...number_of_columns).each do |j|
              @node_map[i]    ||= {}
              @node_map[i][j]   = Node.new(map[i,j])
            end
          end
        end
      end
    end
  end
end
