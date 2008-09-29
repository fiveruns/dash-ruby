require File.dirname(__FILE__) << "/test_helper"

class TracingTest < Test::Unit::TestCase

  attr_reader :metric
  
  def self.time_me(depth = 0)
    time_me(depth + 1) if depth < 5
  end

  context "Tracing" do
    
    setup do
      Thread.current[:trace] = Fiveruns::Dash::Trace.new
    end
    
    teardown do
      # Hacked 'uninstrument' until it's built-in
      ::Fiveruns::Dash::Instrument.handlers.each do |handler|
        (class << TracingTest; self; end).class_eval <<-EOCE
          remove_method :time_me_with_instrument_#{handler.hash}
          alias_method :time_me, :time_me_without_instrument_#{handler.hash}
          remove_method :time_me_without_instrument_#{handler.hash}
        EOCE
      end
      ::Fiveruns::Dash::Instrument.handlers.clear
    end
    
    context "metrics" do
      setup do
        @metric = TimeMetric.new(:time_mes, :method => time_method)
        flexmock(@metric).should_receive(:info_id).and_return(1)
      end
      should "create a call graph" do
        invoke
        assert_correct_graph trace.data
      end
    end
    
  end  
  
  private
  
  def assert_correct_graph(node, depth = 0)
    assert_equal 1, node.children.size
    assert_equal 1, node.metrics.size
    if depth < 4
      node.children.each do |child|
        assert_correct_graph(child, depth + 1)
      end
    end
  end
  
  def trace
    Thread.current[:trace]
  end
  
  def time_method
    'TracingTest.time_me'
  end
  
  def invoke(number = 1)
    number.times { TracingTest.time_me }
  end
  
end