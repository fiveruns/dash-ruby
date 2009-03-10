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
        @configuration = Write::Configuration.new do |config|
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