require_relative './astar/pathfinder'

module TrafficSim
  module Drivers
    class AStar
      def initialize()
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
          path       = pathfinder.find_path(my_position, dock_position, @direction)
          @movements = build_commands(my_position, path)
        end

        @movements.shift
      end

      private

      def build_commands(starting_position, next_moves)
        commands = []
        state = {
          :position  => starting_position,
          :direction => @direction,
          :speed     => @current_speed
        }

        next_moves.each do |move|
          mask = Pathfinder::MOVEMENT_MASK[state[:direction]]
          simple_movement = MapTools.add_vectors(state[:position], mask)

          if simple_movement == move
            commands << :launch
          else
            commands += build_curve_commands(move, state)
          end
          state[:position] = move
        end

        commands
      end

      def build_curve_commands(next_move, state)
        movement_mask     = MapTools.subtract_vectors(next_move, state[:position])
        state[:direction] = Pathfinder::DIRECTION[movement_mask]
        # At this state, the vehicle will be moving, so
        # whe need to reflect it for the next states
        state[:speed]     = 1

        direction_command = :"face_#{state[:direction]}"

        commands = []
        commands << :decrease_speed if state[:speed] > 0
        commands += [direction_command, :increase_speed, :launch]
      end
    end
  end
end
