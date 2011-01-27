require_relative 'astar/pathfinder'

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
          p state
          mask            = Pathfinder::MOVEMENT_MASK[state[:direction]]
          simple_movement = MapTools.add_vectors(state[:position], mask)

          partial_commands = []
          if simple_movement == move
            partial_commands += [:launch]
          else
            partial_commands += [:decrease_speed] if state[:speed] > 0
            partial_commands += build_curve_commands(state[:position],move)
          end

          if partial_commands.include?(:increase_speed)
            state[:speed] = 1
          end
          if command = partial_commands.select { |c| c =~ /face/ }.first
            state[:direction] = direction_of_command(command)
          end

          commands += partial_commands
          state[:position] = move
        end

        commands
      end

      def build_curve_commands(current_position, next_position)
        movement_mask     = MapTools.subtract_vectors(next_position, current_position)
        direction         = Pathfinder::DIRECTION[movement_mask]
        direction_command = :"face_#{direction}"

        [direction_command, :increase_speed, :launch]
      end

      # :face_south => :south
      def direction_of_command(command)
        command.to_s.split('_')[1].to_sym
      end
    end
  end
end
