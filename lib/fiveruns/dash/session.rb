module Fiveruns::Dash
    
  class Session
    
    attr_reader :configuration, :reporter
    def initialize(configuration)
      @configuration = configuration
      @reporter = Reporter.new(self)
    end
    
    def start(background = true)
      @reporter.start(background)
    end
    
    def info
      rollup :info
    end
    
    def data
      rollup :data
    end
    
    #######
    private
    #######

    def rollup(field)
      configuration.metrics.inject({}) do |metrics, metric|
        metrics.merge(metric.__send__(field))
      end
    end
    
  end
      
end