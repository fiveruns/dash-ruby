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
      configuration.metrics.inject({}) do |metrics, metric|
        metrics.update(metric.info)
      end
    end
    
    def data
      configuration.metrics.map { |metric| metric.data }.flatten
    end
        
  end
      
end