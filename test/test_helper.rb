require 'test/unit'
require 'rubygems'

begin
  require 'shoulda'
  require 'flexmock/test_unit'
  require 'fake_web'
rescue LoadError
  puts "Please install the Shoulda, FakeWeb and flexmock gems to run the Dash plugin tests."
end

begin
  require 'redgreen'
rescue LoadError
end

$:.unshift(File.dirname(__FILE__) << '/../lib')
# Require library files
require 'fiveruns/dash'

class Test::Unit::TestCase
  
  include Fiveruns::Dash
  
  def mock!
    no_recipe_loading!
    mock_configuration!
    create_session!
    mock_reporter!
  end
  
  def create_session!
    @session = Write::Session.new(@configuration)
  end
  
  def mock_configuration!
    # Mock Configuration
    @metrics = []
    @metric_class = Class.new(Write::Metric) do
      def self.metric_type
        :test
      end
      def info_id
        1
      end
    end
    3.times do |i|
      @metrics << @metric_class.new("Metric#{i}") { 1 }
    end
    @recipes = []
    @recipes << Fiveruns::Dash::Write::Recipe.new(:foo, :url => 'http://foo.com')
    @recipes << Fiveruns::Dash::Write::Recipe.new(:foo2, :url => 'http://foo2.com')
    @metrics << @metric_class.new("NonCustomMetric") { 2 }
    @metrics << @metric_class.new("BadMetric") { raise ArgumentError }
    @configuration = flexmock(:configuration) do |mock|
      mock.should_receive(:metrics).and_return(@metrics)
      mock.should_receive(:recipes).and_return(@recipes)
    end
  end
  
  def mock_reporter!
    @restarted = false
    flexmock(Write::Reporter).new_instances do |mock|
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
    @original_logdev = Fiveruns::Dash.logger.instance_eval { @logdev }
    @logdev = Fiveruns::Dash.logger.instance_eval { @logdev = StringIO.new }
  end
  
  def no_recipe_loading!
    # For now, we just stub it out so we don't muddy the list of recipes
    # due to environmental factors
    flexmock(Fiveruns::Dash).should_receive(:load_recipes)
  end
  
  def assert_wrote(*args)
    stream = args.last.is_a?(StringIO) ? args.pop : @logdev
    stream.rewind
    content = stream.read.to_s.downcase
    args.each do |word|
      assert content.include?(word.downcase)
    end
  end
  
  def restore_streams!
    if @original_stdout && @original_stderr
      $stdout = @original_stdout
      $stderr = @original_stderr
      Fiveruns::Dash.logger.instance_eval { @logdev = @original_logdev }
    end
  end
    
end
