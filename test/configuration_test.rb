require File.dirname(__FILE__) << "/test_helper"

class ConfigurationTest < Test::Unit::TestCase
  
   context "Configuration" do

    setup do
      no_recipe_loading!
      mock_streams!
    end
    
    teardown do
      restore_streams!
      Fiveruns::Dash.class_eval { @configuration = nil }
    end

    should "update options passed by Fiveruns::Dash.configure convenience method" do
      assert_nil config.options[:app]
      token = 'foo-bar'
      Fiveruns::Dash.configure :app => token
      assert_equal token, config.options[:app]
    end
    
    context "metric definitions" do
      setup do
        @configuration = Configuration.new do |config|
          metric_types.each do |type|
            config.__send__(type, "#{type}") do
              # Empty block for metric types that require it
            end
          end
        end
      end
      should "assign all metrics" do
        assert_equal 3, @configuration.metrics.size
        types = @configuration.metrics.map { |metric| metric.class.metric_type }
        assert_equal metric_types.map { |i| i.to_s }.sort, types.map { |i| i.to_s }.sort
      end
      should "not allow invalid types" do
        assert_raises NoMethodError do
          @configuration.__send__(:bad_type, 'My Horrible Metric')
        end
      end
    end
    
    context "setting by version" do
      setup do
        @version = '0.1.6'
        @config = Configuration.new do |config|
          config.for_version @version, '0.1.6' do
            config.counter :foo do
              1
            end
          end
          config.for_version @version, ['=', '0.1.6'] do
            config.counter :bar do
              1
            end
          end
          config.for_version @version, ['==', '0.1.5'] do
            config.counter :spam do
              1
            end
          end
          config.for_version @version, ['>', '0.1.6'] do
            config.counter :baz do
              1
            end
          end
          config.for_version nil, ['>', '0.1.6'] do
            config.counter :quux do
              1
            end
          end
        end
      end
      should "execute if correct version" do
        assert_equal 2, @config.metrics.size
        assert_equal %w(bar foo), @config.metrics.map { |m| m.name }.map { |i| i.to_s }.sort
      end
    end
    
    context 'for exception annotations' do
      should 'add a block to the list of annotations' do
        config.annotate_exceptions do |metadata|
          metadata[:foo] = 'flop!'
        end
        
        assert_equal 1, 
          ::Fiveruns::Dash.session.
            exception_recorder.exception_annotations.length
      end
    end
    
  end
  
  #######
  private
  #######
  
  def metric_types
    [:counter, :percentage, :absolute]
  end

  def config
    Fiveruns::Dash.configuration
  end

end