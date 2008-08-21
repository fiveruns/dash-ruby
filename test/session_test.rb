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
        assert_equal @metrics.size, session.data.size
      end
    end
    
    context "info" do
      should "have metric_infos" do
        assert_kind_of Array, session.info[:metric_infos]
        assert_equal @metrics.size, session.info[:metric_infos].size
      end
      should "have recipes" do
        assert_kind_of Array, session.info[:recipes]
        session.info[:recipes].each do |recipe|
          assert_kind_of String, recipe[:name]
          assert_kind_of String, recipe[:url]
        end          
      end
      
    end

  end

end