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
    
    context "exceptions" do
      
      should 'add exceptions to the exception recorder' do
        ex = generate_exception
        @session.add_exception(ex)
        
        assert_exception_matches ex, @session.exception_recorder.data.first
      end
      
      context 'annotations' do
        
        should 'run on exception samples' do
          ex = generate_exception
          sample = {:key => 1}
          @session.add_annotater do |metadata|
            metadata.delete :key
            metadata[:foo] = 1
          end
          @session.add_exception(ex, sample)
          
          assert_equal({'foo' => '1'}, 
                       @session.exception_recorder.data.first[:sample])
        end
        
      end
      
    end
    
  end
  
  protected
  
  def assert_exception_matches(exception, hash)
    assert_equal exception.class.to_s, hash[:name]
    assert_equal exception.message, hash[:message]
  end
  
  def generate_exception
    begin
      raise Exception.new("OHS NOES")
    rescue Exception => e
      e
    end
  end

end