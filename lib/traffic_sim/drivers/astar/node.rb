module TrafficSim
  module Drivers
    class AStar
      class Node
        attr_accessor :walking_cost, :total_cost, :destination_cost,
                      :parent_position, :visited, :element

        alias :visited? :visited

        def initialize(element)
          @element = element
          @walking_cost = @destination_cost = @total_cost = 0
        end

        def update(movement)
          @parent_position  = movement.current_position
          @walking_cost     = movement.walking_cost
          @destination_cost = movement.destination_cost
          @total_cost       = movement.total_cost
        end

        def walkable?
          @element.nil?
        end
      end
    end
  end
end
