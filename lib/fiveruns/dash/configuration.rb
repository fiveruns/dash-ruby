module Fiveruns::Dash
  
  class Configuration
    
    delegate :each, :to => :metrics
    
    def self.default_options
      {:scm_repo => Dir.pwd}
    end
    
    attr_reader :options
    def initialize(options = {})
      @options = self.class.default_options.merge(options)
      yield self if block_given?
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
      comparator = requirement.shift || :==
      yield if source_version.__send__(comparator, requirement_version)
    end
    
    def metrics #:nodoc:
      @metrics ||= {}
    end
    
    # Merge in an existing recipe
    # call-seq:
    #   include_recipe :ruby
    def include_recipe(name)
      if Fiveruns::Dash.recipes[name]
        Fiveruns::Dash.recipes[name].each do |recipe|
          recipe.call(self)
        end
      else
        raise ArgumentError, "No such recipe: #{name}"
      end
    end
    
    #######
    private
    #######
    
    def method_missing(meth, *args, &block)
      if (klass = Metric.types[meth])
        metric = klass.new(*args, &block)
        metrics[metric.name] = metric
      else
        super
      end
    end
              
  end 
      
end