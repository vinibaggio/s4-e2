module TrafficSim
  module Drivers
    class AStar
      def initialize(params={})
        @available_nodes   = []
        @closed_nodes      = []
        @movements         = []
        @vehicle_direction = :north
      end

      def step(map, driver_name)
        if @movements.any?
          @movements.pop
        else
          my_position     = find_myself(map, driver_name)
          available_nodes = walkable(surroundings(:map         => map,
                                                  :driver_name => driver_name,
                                                  :position    => my_position
                                                 ))
          available_nodes << {:position => my_position}
        end
      end

      def surroundings(params={})
        map          = params[:map]
        driver_name  = params[:driver_name]
        map_origin   = params[:position]
        surroundings = []

        (-1..1).each do |row_offset|
          (-1..1).each do |column_offset|
            map_i  = map_origin[0] + row_offset
            map_j  = map_origin[1] + column_offset

            surroundings << {
              :element  => map[map_i, map_j],
              :position => [map_i, map_j]
            }
          end
        end

        surroundings
      end

      def find_myself(map, driver_name)
        number_of_cols = map.columns.length
        number_of_rows = map.rows.length

        position = []

        (0...number_of_rows).each do |i|
          (0...number_of_cols).each do |j|
            if map[i,j].is_a?(Vehicle) && map[i, j].driver_name == driver_name
              position = [i,j]
              break
            end
          end
          break if position.any?
        end

        position
      end

      def walkable(nodes)
        nodes.select { |node| node[:element].nil? }
      end

      def total_cost(map, node)

      end

      # Each step iteraction in the Engine counts as 10 points.
      # So when the vehicle just have to move one slot, 10 points
      # When it has to make a turn, 20 points.
      #
      # The other moves are just products of those, such as
      # a simple diagonal move as 30 and more complex one
      # as 40 points. See the tests for more examples.
      MOVEMENT_MASK = {
        :north => [-1, 0],
        :south => [1, 0],
        :east  => [0, 1],
        :west  => [0, -1]
      }.freeze

      def walking_cost(params)
        vehicle_direction = params[:vehicle_direction]
        current_position  = params[:position]
        next_position     = params[:next_position]
        points            = 0

        movement_mask = MOVEMENT_MASK[vehicle_direction]

        # We apply the movement_mask to the original position
        # and get a forward position (by going without turning)
        forward_position = (0..1).map do |idx|
          current_position[idx] + movement_mask[idx]
        end

        # We calculate simple Hamming distance between current
        # position and next_position. It's result is the number
        # of movements we need to do to achieve the final position
        hamming_distance = hamming_distance(current_position, next_position)

        # We need to compare hamming distance of both possibilities
        forward_hamming_distance = hamming_distance(forward_position, next_position)

        if hamming_distance < forward_hamming_distance
          # For each movement, we must turn and accelerate,
          # so we must multiply the points by 2 (10 * 20)
          points += hamming_distance * 20
        else
          # By avoiding the first turn, we first go forward (apply 10 points)
          # and then calculate the moves from the forward position to the
          # final point
          points += 10
          points += forward_hamming_distance * 20
        end

        points
      end

      def hamming_distance(point_a, point_b)
        (0..1).inject(0) do |sum, idx|
          sum += (point_a[idx] - point_b[idx]).abs
        end
      end
    end
  end
end
