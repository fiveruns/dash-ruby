require File.dirname(__FILE__) << "/test_helper"

class MetricTest < Test::Unit::TestCase
  
  attr_reader :metric
  
  def self.time_me
    sleep 0.01
  end

  context "Metric" do

    context "using time" do
      setup do
        @metric = TimeMetric.new(time_method)
      end
      teardown do
        # Hacked 'uninstrument' until 'instrument' gem supports it
        class << MetricTest
          remove_method :time_me_with_instrument
          alias_method :time_me, :time_me_without_instrument
          remove_method :time_me_without_instrument
        end
      end
      should "get correct number of invocations" do
        invoke 4
        assert_invocations_reported 4
        invoke 1
        assert_invocations_reported 1
      end
      should "time invocations" do
        last_total = 0
        4.times do |i|
          invoke
          assert_equal i + 1, current_invocations 
          reported_total = current_time_total
          assert(reported_total > last_total)
          last_total = reported_total
        end
        metric.data # clears
        assert_equal 0, current_time_total
      end
      should "have correct info" do
        assert_equal [time_method], metric.info.keys
        assert_equal time_method, @metric.info[time_method][:description]
      end
    end

  end
  
  #######
  private
  #######
  
  def current_time_total
    metric.instance_eval { @time }
  end
  
  def current_invocations
    metric.instance_eval { @invoked }
  end
  
  def time_method
    'MetricTest.time_me'
  end
  
  def assert_invocations_reported(number = 1)
    assert_equal number, metric.data[time_method][:invoked]
  end

  def invoke(number = 1)
    number.times { MetricTest.time_me }
  end

end