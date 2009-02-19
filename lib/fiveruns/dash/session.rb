module Fiveruns::Dash
    
  class Session
    
    attr_reader :configuration, :reporter
    def initialize(configuration)
      @configuration = configuration
      # eager create the host data in the main thread
      # as it is dangerous to load in the reporter thread
      Fiveruns::Dash.host
    end
    
    def start(background = true, &block)
      Fiveruns::Dash.logger.info "Starting Dash #{Fiveruns::Dash::Util.version_info}"
      reporter.start(background, &block)
    end
    
    def exceptions
      @exceptions ||= []
    end
    
    # Trace and send metric collection
    def trace(name)
      Thread.current[:trace] = ::Fiveruns::Dash::Trace.new(name)
      result = yield
      reporter.send_trace(Thread.current[:trace])
      Thread.current[:trace] = nil
      result
    end
    
    def add_exception(exception, sample=nil)
      exception_recorder.record(exception, sample)
    end
    
    def info
      {
        :recipes => recipe_metadata,
        :metric_infos => metric_metadata
      }
    end
    
    def recipe_metadata
      configuration.recipes.inject([]) do |recipes, recipe|
        recipes << recipe.info
      end
    end
    
    def metric_metadata
      configuration.metrics.inject([]) do |metrics, metric|
        metrics << metric.info
      end
    end
    
    def reset
      exception_recorder.reset
      configuration.metrics.each { |m| m.reset }
    end
    
    def data
      real_data = configuration.metrics.map { |metric| metric.data }.compact
      virtual_data = configuration.metrics.map { |metric| metric.calculate(real_data) }.compact
      # Return any metrics which are not abstract and should be sent to the server
      metric_payload = (real_data + virtual_data).find_all { |data| !data[:abstract] }
      #puts "Sending #{metric_payload.map { |met| [met[:name], met[:values].size] }.inspect} metrics"
      metric_payload
    end

    def exception_data
      exception_recorder.data
    end

    def exception_recorder
      @exception_recorder ||= ExceptionRecorder.new(self)
    end
    
    def reporter
      @reporter ||= Reporter.new(self)
    end
    
  end
      
end