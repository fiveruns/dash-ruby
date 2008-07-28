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
    
    context "data" do
      should "have right number of metrics" do
        assert_equal @metrics.size, session.data[:metrics].size
      end
    end

  end

end