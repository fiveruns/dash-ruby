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
        @reporter = Reporter.new(@session)
      end
      should "start normally" do
        assert !@reporter.started?
        assert !@reporter.background?
        @reporter.start
        assert @reporter.started?
        assert @reporter.background?
        assert !@restarted
      end
      should "allow restart" do
        @reporter.start
        assert !@restarted
        @reporter.start
        assert @restarted
      end
    end

  end
  
  #######
  private
  #######
  

end