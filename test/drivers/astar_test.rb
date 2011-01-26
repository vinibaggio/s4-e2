require_relative "../test_helper"

describe TrafficSim::Drivers::AStar do
  describe "#walking_cost" do
    it "should return 10 when it has the lowest walking cost" do
      params = {
        :vehicle_direction => :north,
        :position          => [1,1],
        :next_position     => [0,1]
      }
      assert_equal 10, subject.walking_cost(params)
    end

    it "should return 20 when it has to turn (two steps)" do
      params = {
        :vehicle_direction => :north,
        :position          => [1,1],
        :next_position     => [1,2]
      }
      assert_equal 20, subject.walking_cost(params)
    end

    it "should return 30 when it has to do a simple diagonal move" do
      params = {
        :vehicle_direction => :north,
        :position          => [1,1],
        :next_position     => [0,0]
      }
      assert_equal 30, subject.walking_cost(params)
    end

    it "should return 40 when it has to do a more complete diagonal move" do
      params = {
        :vehicle_direction => :north,
        :position          => [1,1],
        :next_position     => [2,2]
      }
      assert_equal 40, subject.walking_cost(params)
    end
  end

  private
  def subject
    @subject ||= TrafficSim::Drivers::AStar.new
  end
end
