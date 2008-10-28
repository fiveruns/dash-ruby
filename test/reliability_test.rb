require File.dirname(__FILE__) << "/test_helper"

class Gizmo
  
  def oops!
    raise 'I made an oopsie!'
  end
    
end

class ReliabilityTest < Test::Unit::TestCase
  
  context "The Dash plugin" do
    
    should 'not swallow user-created exceptions' do
      TimeMetric.new(:oops, 'Time spent messing up', 'Ooops!', 
                     :method => 'Gizmo#oops!')
      assert_raises(RuntimeError) { Gizmo.new.oops! }
    end
    
    should 'report an exception if instrumentation cannot proceed' do
      assert_raises(Fiveruns::Dash::Instrument::Error) do
        TimeMetric.new(:wheee, 'Time spent having fun', 'Wheeee!',
                       :method => 'Gizmo.wheeeeeeee!')
        TimeMetric.new(:oops, 'Time spent messing up', 'Ooops!', 
                       :method => 'Gizmo#oops!')
      end
    end
    
    should 'not proceed with instrumentation if an error occurs' do
      begin
        TimeMetric.new(:wheee, 'Time spent having fun', 'Wheeee!',
                       :method => 'Gizmo.wheeeeeeee!')
        TimeMetric.new(:oops, 'Time spent messing up', 'Ooops!', 
                       :method => 'Gizmo#oops!')
      rescue Fiveruns::Dash::Instrument::Error
      end
      assert_equal 0, Fiveruns::Dash.configuration.metrics.length
    end
    
    should 'not modify Thread.abort_on_exception if the user has set it' do
      assert !Thread.abort_on_exception
    end
    
  end
  
end
