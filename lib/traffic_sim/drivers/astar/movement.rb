module TrafficSim
  module Drivers
    class AStar
      class Movement
        MOVEMENT_MASK = {
          :north => [-1, 0],
          :south => [1, 0],
          :east  => [0, 1],
          :west  => [0, -1]
        }.freeze

        DIRECTION = MOVEMENT_MASK.invert.freeze
        COST      = 10

        attr_reader :walking_cost, :destination_cost

        def initialize(params = {})
          @vehicle_direction = params[:vehicle_direction]
          @current_position  = params[:current_position]
          @next_position     = params[:next_position]
          @final_position    = params[:final_position]
          @walking_cost      = calculate_walking_cost
          @destination_cost  = calculate_destination_cost
        end

        def total_cost
          @walking_cost + @destination_cost
        end

        private

        # The walking cost is based on the idea that moving the car is not
        # so simple.
        #
        # Imagine that if the car is moving north, but now it must turn left.
        # It should reduce its speed, move its direction, increase its speed
        # to finally start walking. So each change of direction accounts for 3
        # movements, which has high cost.
        #
        # To calculate the number of movements, we use simple Hamming distance.
        # It is basically the number of space slots it has to move. The
        # Hamming distance is given by calculating the difference for each
        # index of the position
        #
        # Example:
        #
        # Vehicle a has to move from [1,1] to [2,2]. So it must move south
        # and then left. The hamming distance is calculated as the following:
        # |1 - 2| + |1 - 2| = 1 + 1 = 2 slots.
        #
        # With that in mind, we first check if the next position is achievable
        # by only going forward. That is achieved by applying MOVEMENT_MASK
        # and calculate the hamming distances.
        #
        # We pick whichever path that has the least hamming distances, multiply
        # it by the COST and then by 3, which is the number of
        # commands the system needs to achieve the movement.
        def calculate_walking_cost
          points                   = 0
          movement_mask            = MOVEMENT_MASK[@vehicle_direction]
          forward_position         = MapTools.add_vectors(@current_position,
                                                          movement_mask)
          hamming_distance         = hamming_distance(@current_position,
                                                      @next_position)
          forward_hamming_distance = hamming_distance(forward_position,
                                                      @next_position)

          if hamming_distance < forward_hamming_distance
            points += hamming_distance * COST * 3
          else
            points += COST
            points += forward_hamming_distance * COST * 3
          end

          points
        end

        # Calculate a rough estimate of cost of movement to reach
        # the docking using Manhattan method. Need improvements.
        #
        # Estimate two direction changes, and remember that each direction
        # change costs 3 * COST
        def calculate_destination_cost
          hamming_distance(@current_position, @final_position) * COST +
            (2 * 3 * COST)
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
