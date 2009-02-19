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
          assert_metrics(*%w(test1))
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
          assert_metrics(*%w(test1 test2))
        end
        should "allow specific recipe to be loaded" do
          config.add_recipe :test, :url => 'http://test2.com'
          assert_equal 1, config.metrics.size
          assert_metrics(*%w(test2))
        end
      end
      context "and passing settings" do
        setup do
          recipe :settings1, :url => 'http://example.com' do |r|
            r.added do |settings|
              r.counter(settings[:metric]) { }
            end
          end
          config.add_recipe :settings1, :metric => :bar
        end
        should "pass them to the `added' block" do
          assert_equal 1, config.metrics.size
          assert_equal 'bar', config.metrics.first.name
        end
      end
    end
    
    context "when added" do
      setup do
        @fired = false
        recipe :test, :url => 'http://test.com' do |recipe|
          recipe.added do
            @fired = true
          end
          recipe.counter(:countme) { }
        end
      end
      should "fire recipe hook" do
        config.add_recipe :test
        assert @fired
      end
      should "allow metrics with same name and different recipes" do
        config.counter(:countme) { }
        config.add_recipe :test
        assert_metrics(*%w(countme countme))
      end
      context "modifying existing metrics" do
        setup do
          recipe :test3 do |r|
            r.modify :name => :countme do |metric|
              metric.find_context_with do |obj, *args|
                [:modified, true]
              end
            end
          end
        end
        should "only occur on addition" do
          config.metrics.each do |metric|
            if metric.name == 'countme'
              assert_nil metric.instance_eval { @metric_finder }
            end
          end
        end
        should "change context finder" do
          config.add_recipe :test3
          config.metrics.each do |metric|
            if metric.name == 'countme'
              assert_kind_of Proc, metric.instance_eval { @metric_finder }
            end
          end
        end
      end

    end

  end
  
  #######
  private
  #######
  
  def assert_metrics(*names)
    assert_equal names.sort,
                 config.metrics.map { |m| m.name }.map { |m| m.to_s }.sort
  end
  
  def recipe(name = :test, options = {:url => 'http://test.com'}, &block)
    Fiveruns::Dash.register_recipe(name, options, &block)
  end  

end