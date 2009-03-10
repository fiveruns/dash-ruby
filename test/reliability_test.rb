require File.dirname(__FILE__) << "/test_helper"

class Gizmo
  
  def oops!
    raise 'I made an oopsie!'
  end
    
end

class ReliabilityTest < Test::Unit::TestCase
  
  context "FiveRuns Dash" do
    
    should 'not swallow user-created exceptions' do
      dash do |metrics|
        metrics.time(:oops, 'Time spent messing up', 'Ooops!', 
                     :method => 'Gizmo#oops!')
      end
      
      assert_raises(RuntimeError) { Gizmo.new.oops! }
    end
    
    should 'report an exception if instrumentation cannot proceed' do
      assert_raises(Fiveruns::Dash::Write::Instrument::Error) do
        dash do |metrics|
          metrics.time(:wheee, 'Time spent having fun', 'Wheeee!',
                       :method => 'Gizmo.wheeeeeeee!')
          metrics.time(:oops, 'Time spent messing up', 'Ooops!', 
                       :method => 'Gizmo#oops!')
        end
      end
    end
    
    should 'not proceed with instrumentation if an error occurs' do
      begin
        dash do |metrics|
          metrics.time(:wheee, 'Time spent having fun', 'Wheeee!',
                       :method => 'Gizmo.wheeeeeeee!')
          metrics.time(:oops, 'Time spent messing up', 'Ooops!', 
                       :method => 'Gizmo#oops!')
        end
      rescue Fiveruns::Dash::Write::Instrument::Error
      end
      assert_equal 0, Fiveruns::Dash.application.session.configuration.metrics.length
    end
    
    should 'not modify Thread.abort_on_exception if the user has set it' do
      assert !Thread.abort_on_exception
    end
    
  end
  
  def dash(&block)
    Fiveruns::Dash.configure({:app => ENV['DASH_APP']}, &block)
    Fiveruns::Dash.application.session.reporter.interval = 10
    Fiveruns::Dash.application.session.start
  end
  
end
