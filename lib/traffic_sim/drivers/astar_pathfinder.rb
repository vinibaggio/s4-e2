require_relative './astar_nodemap'
require_relative './astar_maptools'
require 'ruby-debug'

module TrafficSim
  module Drivers
    class AStar
      class Pathfinder
        MOVEMENT_MASK = {
          :north => [-1, 0],
          :south => [1, 0],
          :east  => [0, 1],
          :west  => [0, -1]
        }.freeze

        MOVEMENT_COST = 10

        def initialize(map)
          @node_map = NodeMap.new(map)
        end

        # This is an implementation of the A* path finder algorithm.
        # This implementation was based on the following article:
        # http://www.policyalmanac.org/games/aStarTutorial.htm
        def find_path(start_position, final_position, start_direction)
          available_positions = [start_position]

          while !available_positions.empty? && !@node_map.visited?(final_position)

            current_position = lowest_cost_position(available_positions)
            available_positions.delete(current_position)

            @node_map.mark_as_visited(current_position)

            surroundings = possible_surroundings(current_position, final_position)
            surroundings.each do |position|
              params = {
                :vehicle_direction => start_direction,
                :current_position  => current_position,
                :next_position     => position,
                :final_position    => final_position
              }
              walking_cost = walking_cost(params)
              destination_cost = destination_cost(params)
              total_cost = walking_cost + destination_cost

              node = @node_map[*position]

              update_node = false

              if available_positions.include?(position)
                update_node = node.walking_cost > walking_cost
              else
                update_node = true
                available_positions << position
              end

              if update_node
                node.parent_position  = current_position
                node.walking_cost     = walking_cost
                node.destination_cost = destination_cost
                node.total_cost       = total_cost
              end
            end
          end

          make_path(start_position, final_position)
        end

        private
        def lowest_cost_position(positions)
          positions.sort_by do |position|
            @node_map[*position].total_cost
          end.first
        end

        def possible_surroundings(current_position, final_position)
          surroundings = MapTools.surroundings(current_position)
          surroundings = walkable(surroundings, final_position)
          surroundings.reject { |pos| @node_map.visited?(pos) }
        end

        # The final position is always walkable.
        def walkable(positions, final_position)
          positions.select do |position|
            @node_map[*position].walkable? || position == final_position
          end
        end

        def make_path(start_position, final_position)
          path = []

          position = final_position
          while position != start_position
            path << position
            position = @node_map[*position].parent_position
          end

          path.reverse
        end

        # Each step iteraction in the Engine counts as 10 points.
        # So when the vehicle just have to move one slot, 10 points
        # When it has to make a turn, 20 points.
        #
        # The other moves are just products of those, such as
        # a simple diagonal move as 30 and more complex one
        # as 40 points. See the tests for more examples.

        def walking_cost(params)
          vehicle_direction = params[:vehicle_direction]
          current_position  = params[:current_position]
          next_position     = params[:next_position]
          points            = 0

          movement_mask = MOVEMENT_MASK[vehicle_direction]

          # We apply the movement_mask to the original position
          # and get a forward position (by going without turning)
          forward_position = MapTools.add_vectors(current_position, movement_mask)

          # We calculate simple Hamming distance between current
          # position and next_position. Its result is the number
          # of movements we need to do to achieve the final position
          hamming_distance = hamming_distance(current_position, next_position)

          # We need to compare hamming distance of both possibilities
          forward_hamming_distance = hamming_distance(forward_position,
                                                      next_position)

          if hamming_distance < forward_hamming_distance
            # For each movement, we must, deccelerate, turn and accelerate,
            # so we must multiply the points by 3
            points += hamming_distance * MOVEMENT_COST * 3
          else
            # By avoiding the first turn, we first go forward (apply 10 points)
            # and then calculate the moves from the forward position to the
            # final point
            points += MOVEMENT_COST
            points += forward_hamming_distance * MOVEMENT_COST * 3
          end

          points
        end

        # Calculate a rough estimate of cost of movement to reach
        # the docking using Manhattan method. Need improvements.
        def destination_cost(params)
          current_position = params[:current_position]
          final_position = params[:final_position]

          hamming_distance(current_position, final_position) * MOVEMENT_COST +
            # Estimate two direction changes, and remember that each direction
            # change costs 3 * MOVEMENT_COST
            (2 * 3 * MOVEMENT_COST)
        end

        def hamming_distance(point_a, point_b)
          (0..1).inject(0) do |sum, idx|
            sum += (point_a[idx] - point_b[idx]).abs
          end
        end
      end
    end
  end
end
