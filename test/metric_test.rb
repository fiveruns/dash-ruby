require File.dirname(__FILE__) << "/test_helper"

class MetricTest < Test::Unit::TestCase
  
  attr_reader :metric
  
  def self.time_me(val=0)
    if val == 0
      time_me(1)
    end
    sleep 0.01
  end

  context "Metric" do
    
    teardown do
      # Hacked 'uninstrument' until it's built-in
      Write::Instrument.handlers.each do |handler|
        (class << MetricTest; self; end).class_eval <<-EOCE
          remove_method :time_me_with_instrument_#{handler.hash}
          alias_method :time_me, :time_me_without_instrument_#{handler.hash}
          remove_method :time_me_without_instrument_#{handler.hash}
        EOCE
      end
      Write::Instrument.handlers.clear
    end
    
    context "should parse arguments for name, description and help_text" do
      setup do
        @options = Hash.new
        @options[:method] = time_method
        @metric = Write::TimeMetric.new(:name, "Description", "HelpText", :method => time_method)
      end
      
      should "interpret name" do
        assert_equal "name", @metric.name
      end

      should "interpret description" do
        assert_equal "Description", @metric.description
      end

      should "interpret help text" do
        assert_equal "HelpText", @metric.help_text
      end

      should "interpret options" do
        assert_equal @options, @metric.options
      end
    end
    
    context "should parse arguments for name, description using defaults" do
      setup do
        @options = Hash.new
        @options[:method] = time_method
        @metric = Write::TimeMetric.new(:name, :method => time_method)
      end
      
      should "interpret name" do
        assert_equal "name", @metric.name
      end

      should "default description to titleized name" do
        assert_equal "Name", @metric.description
      end

      should "default help text to nil" do
        assert_nil @metric.help_text
      end

      should "interpret options" do
        assert_equal @options, @metric.options
      end
    end

    context "using reentrant time" do
      setup do
        @metric = Write::TimeMetric.new(:time_mes, :method => time_method, :reentrant => true)
        flexmock(@metric).should_receive(:info_id).and_return(1)
      end
      teardown do
        # Hacked 'uninstrument' until it's built-in
        Write::Instrument.handlers.each do |handler|
          (class << MetricTest; self; end).class_eval <<-EOCE
            remove_method :time_me_with_instrument_#{handler.hash}
            alias_method :time_me, :time_me_without_instrument_#{handler.hash}
            remove_method :time_me_without_instrument_#{handler.hash}
          EOCE
        end
        Write::Instrument.handlers.clear
      end
      should "get correct number of invocations" do
        invoke 4
        assert_invocations_reported 4
        invoke 1
        assert_invocations_reported 1
      end
    end
    
    context "using time" do
      setup do
        @metric = Write::TimeMetric.new(:time_mes, :method => time_method)
        flexmock(@metric).should_receive(:info_id).and_return(1)
      end
      teardown do
        # Hacked 'uninstrument' until it's built-in
        Write::Instrument.handlers.each do |handler|
          (class << MetricTest; self; end).class_eval <<-EOCE
            remove_method :time_me_with_instrument_#{handler.hash}
            alias_method :time_me, :time_me_without_instrument_#{handler.hash}
            remove_method :time_me_without_instrument_#{handler.hash}
          EOCE
        end
        Write::Instrument.handlers.clear
      end
      should "raise exception without :on option" do
        assert_raises ArgumentError do
          Write::TimeMetric.new(:time_mes, 'A Name')
        end
      end
      should "get correct number of invocations" do
        invoke 4
        assert_invocations_reported 8
        invoke 1
        assert_invocations_reported 2
      end
      should "time invocations" do
        last_total = 0
        4.times do |i|
          invoke
          assert_equal (i + 1)*2, current_invocations 
          reported_total = current_time_total
          assert(reported_total > last_total)
          last_total = reported_total
        end
        metric.data # clears
        assert_equal 0, current_time_total
      end
      should "have correct info" do
        assert_equal 'time_mes', metric.info[:name]
        assert_equal 'Time Mes', metric.info[:description]
      end
      should "be able to set context finder" do
        finder = lambda { |obj, *args| [:class, obj.name] }
        @metric.find_context_with(&finder)
        invoke 4
        assert_equal 8, metric.data[:values].select { |m| m[:context] == [:class, 'MetricTest'] }.first[:invocations]
      end
    end

    context "using incremented counter" do
      setup do
        @metric = Write::CounterMetric.new(:time_mes_counter, :incremented_by => time_method)
        flexmock(@metric).should_receive(:info_id).and_return(1)
      end
      should "default to 0 before being incremented, and after reset" do
        assert_counted 0
        invoke 4
        assert_counted 8
        assert_counted 0
      end
      should "get correct number after being incremented" do
        invoke 4
        assert_counted 8
      end
    end

  end
  
  #######
  private
  #######
  
  def current_time_total
    metric.instance_eval { @data[[]][:value] }
  end
  
  def current_invocations
    metric.instance_eval { @data[[]][:invocations] }
  end
  
  def time_method
    'MetricTest.time_me'
  end
  
  def assert_counted(number)
    counted = nil
    assert_nothing_raised do
      # We fetch to ensure values aren't just being returned due to hash defaults
      counted = metric.data[:values].detect { |m| m[:context] == [] }[:value]
    end
    assert_kind_of Numeric, counted
    assert_equal number, counted
  end
  
  def assert_invocations_reported(number = 1)
    assert_equal number, metric.data[:values].detect { |m| m[:context] == [] }[:invocations]
  end

  def invoke(number = 1)
    number.times { MetricTest.time_me }
  end

end