module Fiveruns::Dash
  
  class Recipe
    
    class ConfigurationError < ::ArgumentError; end
    
    def self.scope_stack
      @scope_stack ||= []
    end
    
    def self.current
      scope_stack.last
    end
    
    def self.in_scope(recipe)
      scope_stack << recipe
      yield
      scope_stack.pop
    end
    
    attr_reader :name, :url, :options
    def initialize(name, options = {}, &block)
      @name = name
      @options = options
      @url = options[:url]
      @block = block
      validate!
    end
    
    def add_to(configuration)
      self.class.in_scope self do
        @block.call(configuration)
      end
    end
    
    def matches?(criteria)
      criteria.all? { |k, v| options[k] == v }
    end
    
    #######
    private
    #######

    def validate!
      unless @url
        raise ConfigurationError, "Recipe requires :url option"
      end
    end
    
    class Loader
      
      delegate :logger, :recipes, :to => Fiveruns::Dash
      
      def run
        load_core_recipes
        load_gem_recipes
      end
      
      #######
      private
      #######
            
      def load_core_recipes
        logger.warn "Registering core recipes"
        track do
          Dir[File.dirname(__FILE__) << "/../../../recipes/*.rb"].each do |file|
            require file
          end
        end
      end

      def load_gem_recipes
        logger.info "Registering gem recipes..."
        spec_path = File.join(Gem.dir, 'specifications')
        gems = Gem::SourceIndex.from_installed_gems(spec_path)
        gems.each do |path, gem|
          gem.dependencies.each do |dependency|
            if dependency.name == 'fiveruns_dash'
              gem_path = File.join(Gem.dir, "gems", path)
              logger.info "Registering recipes from #{path}"
              track do
                Dir[File.join(gem_path, 'dash/**/*.rb')].each do |file|                
                  require file
                end
              end
            end
          end
        end
      end

      def track
        list = recipes.values.flatten.dup
        yield
        delta = recipes.values.flatten - list
        delta.each do |recipe|
          logger.info "> Registered `#{recipe.name}' (#{recipe.url})"
        end
      end
    
    end
    
  end
  
end