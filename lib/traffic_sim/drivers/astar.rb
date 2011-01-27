require_relative './astar_pathfinder'

module TrafficSim
  module Drivers
    class AStar
      def initialize(params={})
        @movements         = []
        @vehicle_direction = :north
      end

      def step(map, driver_name)
        if @movements.any?
          @movements.pop
        else
          pois                = MapTools.points_of_interest(map, driver_name)
          my_position         = pois[:vehicle_position]
          dock_position       = pois[:dock_position]

          pathfinder = Pathfinder.new(map)
          node_map = pathfinder.find_path(my_position, dock_position, @vehicle_direction)

          print_path(map, node_map, my_position, dock_position)
        end
      end

      def print_path(map, node_map, my_position, dock_position)
        position = dock_position
        map_copy = Marshal.load(Marshal.dump(map))
        while position != my_position
          map_copy[*position] = 'X'
          position = node_map[*position].parent_position
        end
        p map_copy
      end
    end
  end
end
