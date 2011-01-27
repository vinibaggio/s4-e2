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

        def mark_as_visited
          @visited = true
        end

        def walkable?
          @element.nil?
        end
      end
    end
  end
end
