require File.dirname(__FILE__) << "/test_helper"

class SessionTest < Test::Unit::TestCase
  
  attr_reader :session

  context "Session" do

    setup do
      mock!
      @session = Session.new(@configuration)
    end

    should "start reporter in background by default" do
      session.start
      assert session.reporter.started?
      assert session.reporter.background?
    end
    
    should "optionally start reporter in foreground" do
      session.start(false)
      assert session.reporter.started?
      assert session.reporter.foreground?
    end
    
    context "info" do
      should "only include family=:custom metrics" do
        custom_metrics = @metrics.select { |m| m.family == :custom}
        assert_equal custom_metrics.size, session.info.size
      end
    end

    context "data" do
      should "have right number of metrics" do
        assert_equal @metrics.size, session.data.size
      end
      should "have right metrics" do
        @metrics.each do |metric|
          assert session.data.detect { |m| m[:name] == metric.name }
        end
      end
    end

  end

end