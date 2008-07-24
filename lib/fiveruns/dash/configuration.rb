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
    
    def metrics
      @metrics ||= {}
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