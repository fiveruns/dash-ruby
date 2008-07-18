require 'test/unit'
require 'rubygems'
require 'Shoulda'
require 'flexmock/test_unit'

require 'rubygems'
require 'fake_web'

$:.unshift(File.dirname(__FILE__) << '/../lib')
# Require library files
require 'fiveruns/dash'

class Test::Unit::TestCase
  
  include Fiveruns::Dash
  
  def mock!
    mock_configuration!
    create_session!
    mock_reporter!
  end
  
  def create_session!
    @session = Session.new(@configuration)
  end
  
  def mock_configuration!
    # Mock Configuration
    @metrics = []
    @metric_class = Class.new(Metric) do
      def self.metric_type
        :test
      end
    end
    3.times do |i|
      @metrics << @metric_class.new("Metric#{i}") { 1 }
    end
    @configuration = flexmock(:configuration) do |mock|
      mock.should_receive(:metrics).and_return(@metrics)
    end
  end
  
  def mock_reporter!
    @restarted = false
    flexmock(Reporter).new_instances do |mock|
      mock.should_receive(:run).and_return do |restarted|
        @restarted = restarted
      end
    end
  end
  
  def mock_streams!
    @original_stdout = $stdout
    $stdout = StringIO.new
    @original_stderr = $stderr
    $stderr = StringIO.new
  end
  
  def restore_streams!
    $stdout = @original_stdout
    $stderr = @original_stderr
  end
    
end
