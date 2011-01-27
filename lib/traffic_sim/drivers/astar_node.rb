module TrafficSim
  module Drivers
    class AStar
      class Node
        attr_accessor :walking_cost, :total_cost, :destination_cost,
                      :parent_position, :visited, :element

        alias :visited? :visited

        def initialize(element)
          @element = element
        end

        def mark_as_visited
          @visited = true
        end
      end
    end
  end
end
