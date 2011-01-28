module TrafficSim
  module Drivers
    class AStar
      module MapTools
        extend self
        def add_vectors(vector_a, vector_b)
          (0..1).map do |idx|
            vector_a[idx] + vector_b[idx]
          end
        end

        def subtract_vectors(vector_a, vector_b)
          (0..1).map do |idx|
            vector_a[idx] - vector_b[idx]
          end
        end
      end
    end
  end
end

