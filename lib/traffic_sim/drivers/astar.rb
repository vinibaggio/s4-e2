module TrafficSim
  module Drivers
    class NodeMap
      def initialize
        @node_map = {}
      end

      def [](row, column)
        @node_map[row][column]
      end

      def []=(row, column, val)
        @node_map[row][column] = val
      end

      def copy_map_elements(map)
        number_of_columns = map.columns.length
        number_of_rows    = map.rows.length
        (0...number_of_rows).each do |i|
          (0...number_of_columns).each do |j|
            @node_map[i]              ||= {}
            @node_map[i][j]           ||= {}
            @node_map[i][j][:element]   = map[i,j]
          end
        end
      end
    end

    class AStar
      MOVEMENT_MASK = {
        :north => [-1, 0],
        :south => [1, 0],
        :east  => [0, 1],
        :west  => [0, -1]
      }.freeze

      MOVEMENT_COST = 10

      def initialize(params={})
        @movements         = []
        @vehicle_direction = :north
        @node_map          = NodeMap.new
      end

      def step(map, driver_name)
        if @movements.any?
          @movements.pop
        else
          pois                = find_points_of_interest(map, driver_name)
          my_position         = pois[:vehicle_position]
          dock_position       = pois[:dock_position]
          available_positions = [my_position]
          closed_positions    = []

          @node_map.copy_map_elements(map)

          require 'ruby-debug'
          while !available_positions.empty? && !found_final_position?(closed_positions, driver_name)
            current_position = lowest_cost_position(available_positions)

            available_positions -= [current_position]
            closed_positions << current_position

            surroundings = surroundings(:map         => map,
                                        :driver_name => driver_name,
                                        :position    => current_position
                                       )

            surroundings = walkable(surroundings, driver_name)
            surroundings -= closed_positions

            surroundings.each do |position|
              params = {
                :vehicle_direction => @vehicle_direction,
                :current_position  => current_position,
                :next_position     => position,
                :dock_position     => dock_position
              }
              walking_cost = walking_cost(params)
              destination_cost = destination_cost(params)
              total_cost = walking_cost + destination_cost

              node = @node_map[*position]

              update_node = false
              if available_positions.include?(position)
                update_node = node[:walking_cost] > walking_cost
              else
                update_node = true
                available_positions << position
              end

              if update_node
                node[:parent]           = current_position
                node[:walking_cost]     = walking_cost
                node[:destination_cost] = destination_cost
                node[:total_cost]       = total_cost
              end
            end
          end
          print_path(map, my_position, dock_position)
        end
      end

      def print_path(map, my_position, dock_position)
        position = dock_position
        map_copy = Marshal.load(Marshal.dump(map))
        while position != my_position
          map_copy[*position] = 'X'
          position = @node_map[*position][:parent]
        end
        p map_copy
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

            unless row_offset == 0 && column_offset == 0 # do not include itself
              surroundings << [map_i, map_j]
            end
          end
        end

        surroundings
      end


      def find_points_of_interest(map, driver_name)
        number_of_cols = map.columns.length
        number_of_rows = map.rows.length
        my_position    = []
        dock_position  = []

        (0...number_of_rows).each do |i|
          (0...number_of_cols).each do |j|
            if map[i,j].is_a?(Vehicle) && map[i, j].driver_name == driver_name
              my_position = [i,j]
            end

            if map[i,j].is_a?(Dock) && map[i, j].owned_by?(driver_name)
              dock_position = [i,j]
            end
          end
        end

        {:vehicle_position => my_position, :dock_position => dock_position}
      end

      def walkable(positions, driver_name)
        positions.select do |position|
          node = @node_map[*position]
          node[:element].nil? ||
            (node[:element].is_a?(Dock) && node[:element].owned_by?(driver_name))
        end
      end

      def lowest_cost_position(positions)
        positions.sort_by do |position|
          @node_map[*position][:cost]
        end.first
      end

      def found_final_position?(closed_positions, driver_name)
        closed_positions.map do |position|
          node = @node_map[*position]
          node[:element].is_a?(Dock) && node[:element].owned_by?(driver_name)
        end.any?
      end

      def total_cost(params)
        current_position = params[:current_position]
        next_position    = params[:next_position]
        dock_position    = params[:dock_position]
        position         = params[:vehicle_position]

        walking_cost(
          :current_position => current_position,
          :next_position    => next_position,
          :vehicle_position => position
        ) + destination_cost(current_position, dock_position)
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
        forward_position = (0..1).map do |idx|
          current_position[idx] + movement_mask[idx]
        end

        # We calculate simple Hamming distance between current
        # position and next_position. Its result is the number
        # of movements we need to do to achieve the final position
        hamming_distance = hamming_distance(current_position, next_position)

        # We need to compare hamming distance of both possibilities
        forward_hamming_distance = hamming_distance(forward_position, next_position)

        if hamming_distance < forward_hamming_distance
          # For each movement, we must turn and accelerate,
          # so we must multiply the points by 2
          points += hamming_distance * MOVEMENT_COST * 2
        else
          # By avoiding the first turn, we first go forward (apply 10 points)
          # and then calculate the moves from the forward position to the
          # final point
          points += MOVEMENT_COST
          points += forward_hamming_distance * MOVEMENT_COST * 2
        end

        points
      end

      # Calculate a rough estimate of cost of movement to reach
      # the docking using Manhattan method. Need improvements.
      def destination_cost(params)
        current_position = params[:current_position]
        dock_position = params[:dock_position]

        hamming_distance(current_position, dock_position) * MOVEMENT_COST +
          # Estimate two direction changes, and remember that each direction
          # change costs 2 * MOVEMENT_COST
          (2 * 2 * MOVEMENT_COST)
      end

      def hamming_distance(point_a, point_b)
        (0..1).inject(0) do |sum, idx|
          sum += (point_a[idx] - point_b[idx]).abs
        end
      end
    end
  end
end
