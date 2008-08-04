require File.dirname(__FILE__) << "/test_helper"

class RecipeTest < Test::Unit::TestCase

  context "Recipe" do

    setup do
      Fiveruns::Dash.recipes.clear
      @config = Fiveruns::Dash::Configuration.new
    end
    
    context "when registering" do
      setup do
        Fiveruns::Dash.register_recipe :test do |metrics|
          metrics.counter :foo do
            1
          end
        end
      end
      should "is added to available recipes" do
        assert_equal 1, Fiveruns::Dash.recipes.size
        assert_kind_of Array, Fiveruns::Dash.recipes[:test]
      end
    end
    
    context "when included" do
      setup do
        @fired = false
        Fiveruns::Dash.register_recipe :test do |metrics|
          metrics.included do
            @fired = true
          end
        end
      end
      should "fire recipe hook" do
        Fiveruns::Dash.configure do |metrics|
          metrics.include_recipe :test
        end
        assert @fired
      end
    end

  end

end