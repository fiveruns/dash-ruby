module Fiveruns::Dash
    
  class Session
    
    attr_reader :configuration, :reporter
    def initialize(configuration)
      @configuration = configuration
    end
    
    def start(background = true, &block)
      reporter.start(background, &block)
    end
    
    def exceptions
      @exceptions ||= []
    end
    
    def add_exception(exception, sample=nil)
      exception_recorder.record(exception, sample)
    end
    
    def info
      configuration.metrics.inject({}) do |metrics, metric|
        metrics.update(metric.info)
      end
    end
    
    def reset
      exception_recorder.reset
      configuration.metrics.each(&:reset)
    end
    
    def data
      {
        :exceptions => exception_recorder.data,
        :metrics => configuration.metrics.map { |metric| metric.data }.flatten
      }
    end
    
    def exception_recorder
      @exception_recorder ||= ExceptionRecorder.new(self)
    end
    
    def reporter
      @reporter ||= Reporter.new(self)
    end
    
  end
      
end