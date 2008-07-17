require File.dirname(__FILE__) << "/test_helper"

class ConfigurationTest < Test::Unit::TestCase

  context "Configuration" do
    
    teardown do
      Fiveruns::Dash.class_eval { @configuration = nil }
    end

    should "update options passed by Fiveruns::Dash.configure convenience method" do
      assert_nil config.options[:app]
      token = 'foo-bar'
      Fiveruns::Dash.configure :app => token
      assert_equal token, config.options[:app]
    end

  end
  
  #######
  private
  #######

  def config
    Fiveruns::Dash.configuration
  end

end