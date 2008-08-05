require File.dirname(__FILE__) << "/test_helper"

class RecipeTest < Test::Unit::TestCase

  context "Recipe" do

    setup do
      Fiveruns::Dash.recipes.clear
      @config = Fiveruns::Dash::Configuration.new
    end
        
    context "when registering" do
      context "with valid metadata" do
        setup do
          assert_nothing_raised do
            Fiveruns::Dash.register_recipe :test, :url => 'http://test.com' do |metrics|
              metrics.counter :foo do
                1
              end
            end
          end
        end
        should "is added to available recipes" do
          assert_equal 1, Fiveruns::Dash.recipes.size
          assert_kind_of Array, Fiveruns::Dash.recipes[:test]
          assert_kind_of Fiveruns::Dash::Recipe, Fiveruns::Dash.recipes[:test].first
        end
      end
      context "without url" do
        should "raise error" do
          assert_raises Fiveruns::Dash::Recipe::ConfigurationError do
            Fiveruns::Dash.register_recipe :test do |metrics|
              metrics.counter :foo do
                1
              end
            end
          end
        end
      end

    end
    
    context "when included" do
      setup do
        @fired = false
        Fiveruns::Dash.register_recipe :test, :url => 'http://test.com' do |metrics|
          metrics.included do
            @fired = true
          end
        end
      end
      should "fire recipe hook" do
        Fiveruns::Dash.configure do |metrics|
          metrics.add_recipe :test
        end
        assert @fired
      end
    end

  end

end