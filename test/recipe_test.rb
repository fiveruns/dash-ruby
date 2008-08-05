require File.dirname(__FILE__) << "/test_helper"

class RecipeTest < Test::Unit::TestCase
  
  attr_reader :config

  context "Recipe" do

    setup do
      mock_streams!
      Fiveruns::Dash.recipes.clear
      @config = Fiveruns::Dash::Configuration.new
    end
    
    teardown do
      restore_streams!
    end
        
    context "when registering" do
      context "with valid metadata" do
        setup do
          assert_nothing_raised do
            recipe do |metrics|
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
            recipe(:test, {}) do |metrics|
              metrics.counter :foo do
                1
              end
            end
          end
        end
      end

    end
    
    context "when adding" do
      context "with single matching recipe" do
        setup do
          recipe :test, :url => 'http://test1.com' do |r|
            r.counter(:test1) { }
          end
          config.add_recipe :test
        end
        should "description" do
          assert_equal 1, config.metrics.size
          assert_equal %w(test1), config.metrics.keys.map(&:to_s).sort
        end
      end
      context "with multiple similiarly-named recipes" do
        setup do
          recipe :test, :url => 'http://test1.com' do |r|
            r.counter(:test1) { }
          end
          recipe :test, :url => 'http://test2.com' do |r|
            r.counter(:test2) { }
          end
        end
        should "load all by default" do
          config.add_recipe :test
          assert_equal 2, config.metrics.size
          assert_equal %w(test1 test2), config.metrics.keys.map(&:to_s).sort
        end
        should "allow specific recipe to be loaded" do
          config.add_recipe :test, :url => 'http://test2.com'
          assert_equal 1, config.metrics.size
          assert_equal %w(test2), config.metrics.keys.map(&:to_s).sort
        end
      end
    end
    
    context "when added" do
      setup do
        @fired = false
        recipe :test, :url => 'http://test.com' do |recipe|
          recipe.included do
            @fired = true
          end
          recipe.counter(:countme) { }
        end
      end
      should "fire recipe hook" do
        config.add_recipe :test
        assert @fired
      end
      should "warn on metrics collision" do
        config.counter(:countme) { }
        config.add_recipe :test
        assert_wrote 'countme', 'previously defined metric'
      end
    end

  end
  
  #######
  private
  #######
  
  def recipe(name = :test, options = {:url => 'http://test.com'}, &block)
    Fiveruns::Dash.register_recipe(name, options, &block)
  end  

end