require File.dirname(__FILE__) << "/test_helper"

class ReporterTest < Test::Unit::TestCase
  
  include Fiveruns::Dash
  
  attr_reader :reporter

  context "Reporter" do

    setup do
      mock!
    end
    
    context "instance" do
      setup do
        @reporter = Write::Reporter.new(@session)
      end
      should "start normally" do
        assert !@reporter.started?
        assert !@reporter.background?
        @reporter.start
        assert_kind_of Time, @reporter.started_at
        assert @reporter.started?
        assert @reporter.background?
        assert !@restarted
      end
      should "allow restart" do
        @reporter.start
        time = @reporter.started_at
        assert_kind_of Time, time
        assert !@restarted
        @reporter.start
        assert @restarted
        assert_equal time.to_f, @reporter.started_at.to_f
      end
    end

  end

end