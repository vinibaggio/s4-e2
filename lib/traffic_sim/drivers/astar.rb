require_relative './astar/pathfinder'

module TrafficSim
  module Drivers
    class AStar
      def initialize(params={})
        @movements     = []
        @direction     = :north
        @current_speed = 0
      end

      def step(map, driver_name)
        if @movements.empty?
          pois          = MapTools.points_of_interest(map, driver_name)
          my_position   = pois[:vehicle_position]
          dock_position = pois[:dock_position]

          pathfinder = Pathfinder.new(map)
          path = pathfinder.find_path(my_position, dock_position, @direction)
          @movements = build_commands(my_position, path)
        end

        @movements.shift
      end

      private

      def build_commands(starting_position, next_moves)
        commands = []
        current_position  = starting_position
        current_direction = @direction
        current_speed     = @current_speed

        next_moves.each do |move|
          mask = Pathfinder::MOVEMENT_MASK[current_direction]
          simple_movement = MapTools.add_vectors(current_position, mask)

          if simple_movement == move
            commands << :launch
          else
            movement_mask     = MapTools.subtract_vectors(move, current_position)
            current_direction = Pathfinder::DIRECTION[movement_mask]
            direction_command = :"face_#{current_direction}"

            commands << :decrease_speed if current_speed > 0
            commands += [direction_command, :increase_speed, :launch]
            current_speed = 1
          end
          current_position = move
        end

        commands
      end
    end
  end
end
