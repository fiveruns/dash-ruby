module Fiveruns::Dash
  
  class Configuration
    
    class ConflictError < ::ArgumentError; end
    
    def each(&block)
      metrics.each(&block)
    end
    
    def self.default_options
      {:scm_repo => Dir.pwd}
    end
    
    attr_reader :options
    def initialize(options = {})
      @options = self.class.default_options.merge(options)
      yield self if block_given?
    end
    
    def ready?
      options[:app]
    end

    # Optionally add to a recipe if the given version meets
    # a requirement
    # Note: Requires RubyGems-compatible version scheme (ie, MAJOR.MINOR.PATCH)
    #
    # call-seq:
    #   for_version Rails::Version::CURRENT, ['>=', '2.1.0'] do
    #     # ... code to execute
    #   end
    def for_version(source, requirement)
      unless source
        ::Fiveruns::Dash.logger.warn "No version given (to check against #{requirement.inspect}), skipping block"
        return false
      end
      source_version = ::Gem::Version.new(source.to_s)
      requirement = Array(requirement)
      requirement_version = ::Gem::Version.new(requirement.pop)
      comparator = normalize_version_comparator(requirement.shift || :==)
      yield if source_version.__send__(comparator, requirement_version)
    end
    
    def metrics #:nodoc:
      @metrics ||= []
    end
    
    def recipes
      @recipes ||= []
    end
    
    def ignore_exceptions(&rule)
      Fiveruns::Dash::ExceptionRecorder.add_ignore_rule(&rule)
    end

    def add_exceptions_from(*meths, &block)
      block = block ? block : lambda { }
      meths.push :exceptions => true
      Instrument.add(*meths, &block)
    end
    
    # Merge in an existing recipe
    # call-seq:
    #   add_recipe :ruby
    def add_recipe(name, options = {}, &block)
      Fiveruns::Dash.register_recipe(name, options, &block) if block_given?
      if Fiveruns::Dash.recipes[name]
        Fiveruns::Dash.recipes[name].each do |recipe|
          if !recipes.include?(recipe) && recipe.matches?(options)
            recipes << recipe
            with_recipe_settings(options.reject { |k, _| k == :url }) do
              recipe.add_to(self) 
            end
          end
        end
      else
        raise ArgumentError, "No such recipe: #{name}"
      end
    end
    
    # Lookup metrics for modification by subsequent recipes
    def modify(criteria = {})
      metrics.each do |metric|
        if criteria.all? { |k, v| metric.key[k].to_s == v.to_s }
          yield metric
        end
      end        
    end
    
    # Optionally fired by recipes when included
    def added
      yield current_recipe_settings
    end
    
    #######
    private
    #######
    
    def with_recipe_settings(settings = {})
      recipe_settings_stack << settings
      yield 
      recipe_settings_stack.pop
    end
    
    def current_recipe_settings
      recipe_settings_stack.last
    end
    
    def recipe_settings_stack
      @recipe_settings_stack ||= []
    end
    
    def normalize_version_comparator(comparator)
      comparator.to_s == '=' ? '==' : comparator
    end
    
    def method_missing(meth, *args, &block)
      if (klass = Metric.types[meth])
        metric = klass.new(*args, &block)
        metric.recipe = Recipe.current
        if metrics.include?(metric)
          Fiveruns::Dash.logger.info "Skipping previously defined metric `#{metric.name}'"
        else
          metrics << metric
        end
      else
        super
      end
    end
              
  end 
      
end