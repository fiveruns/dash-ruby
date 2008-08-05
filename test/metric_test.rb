require File.dirname(__FILE__) << "/test_helper"

class MetricTest < Test::Unit::TestCase
  
  attr_reader :metric
  
  def self.time_me
    sleep 0.01
  end

  context "Metric" do

    context "using time" do
      setup do
        @metric = TimeMetric.new(:time_mes, :method => time_method)
        flexmock(@metric).should_receive(:info_id).and_return(1)
      end
      teardown do
        # Hacked 'uninstrument' until it's built-in
        ::Fiveruns::Dash::Instrument.handlers.each do |handler|
          (class << MetricTest; self; end).class_eval <<-EOCE
            remove_method :time_me_with_instrument_#{handler.hash}
            alias_method :time_me, :time_me_without_instrument_#{handler.hash}
            remove_method :time_me_without_instrument_#{handler.hash}
          EOCE
        end
        ::Fiveruns::Dash::Instrument.handlers.clear
      end
      should "raise exception without :on option" do
        assert_raises ArgumentError do
          TimeMetric.new(:time_mes, 'A Name')
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
        assert_equal ['time_mes'], metric.info.keys
        assert_equal 'Time Mes', @metric.info['time_mes'][:description]
      end
    end

  end
  
  #######
  private
  #######
  
  def current_time_total
    metric.instance_eval { @data[nil][:value] }
  end
  
  def current_invocations
    metric.instance_eval { @data[nil][:invocations] }
  end
  
  def time_method
    'MetricTest.time_me'
  end
  
  def assert_invocations_reported(number = 1)
    assert_equal number, metric.data[:value][nil][:invocations]
  end

  def invoke(number = 1)
    number.times { MetricTest.time_me }
  end

end