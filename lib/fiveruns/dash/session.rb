module Fiveruns::Dash
    
  class Session
    
    attr_reader :configuration, :reporter
    def initialize(configuration)
      @configuration = configuration
      @reporter = Reporter.new(self)
    end
    
    def start(background = true, &block)
      @reporter.start(background, &block)
    end
    
    def exceptions
      @exceptions ||= []
    end
    
    def add_exception(e)
      exceptions << extract_data_from_exception(e)
    end
    
    def info
      configuration.metrics.inject({}) do |metrics, metric|
        metrics.update(metric.info)
      end
    end
    
    def data
      result = {
        :exceptions => exceptions.dup,
        :metrics => configuration.metrics.map { |metric| metric.data }.flatten
      }
      exceptions.clear
      result
    end
    
    def extract_data_from_exception(e)
      {
        :name => e.class.name,
        :message => e.message,
        :backtrace => e.backtrace
      }
    end
    
  end
      
end