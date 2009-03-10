class Fiveruns::Dash::Write::Configuration
    
  class ConflictError < ::ArgumentError; end
  
  def each(&block)
    metrics.each(&block)
  end
  
  def self.default_options
    {:scm_repo => Dir.pwd}
  end
  
  attr_reader :application, :options
  def initialize(application, options = {})
    @application = application
    load_recipes
    @options = self.class.default_options.merge(options)
    yield self if block_given?
  end
  
  def update(opts={})
    if opts[:app]
      opts[:token] = opts.delete(:app)
    end
    options.update(opts)
  end
  
  def token
    options[:token]
  end
  
  def ready?
    options[:token]
  end
  
  def session
    application.session
  end
  
  def metrics #:nodoc:
    @metrics ||= []
  end
  
  def recipes
    @recipes ||= []
  end
  
  def ignore_exceptions(&rule)
    Fiveruns::Dash::Write::ExceptionRecorder.add_ignore_rule(&rule)
  end

  def add_exceptions_from(*meths, &block)
    block = block ? block : lambda { }
    meths.push :exceptions => true
    Fiveruns::Dash::Write::Instrument.add(*meths, &block)
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
  
  def load_recipes
    Dir[File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'recipes', '**', '*.rb')].each do |core_recipe|
      require core_recipe
    end
  end
  
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
    if (klass = Fiveruns::Dash::Write::Metric.types[meth])
      metric = klass.new(*args, &block)
      metric.recipe = Fiveruns::Dash::Write::Recipe.current
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