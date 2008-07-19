module Fiveruns::Dash
    
  class Metric
          
    def self.inherited(klass)
      types[klass.metric_type] = klass
    end
    
    def self.types
      @types ||= {}
    end
    
    attr_reader :name, :description
    def initialize(name, description = name.to_s, &block)
      @name = name
      @description = description
      @operation = block
    end
    
    def info
      {name => {:type => self.class.metric_type, :description => description}}
    end
    
    def data
      {name => current_value}
    end

    #######
    private
    #######
    
    def current_value
      @operation.call
    end
    
    def self.metric_type
      @metric_type ||= name.demodulize.underscore.sub(/_metric$/, '').to_sym
    end
    
  end
  
  class TimeMetric < Metric
    
    def initialize(*args)
      super(*args)
      reset
      install_hook
    end
    
    #######
    private
    #######
    
    def current_value
      returning(:time => @time, :invoked => @invoked) do |value|
        reset
      end
    end
    
    def reset
      @invoked = @time = 0
    end

    def install_hook
      instrument name do |obj, time, *args|
        @invoked += 1
        @time += time
      end
    end
    
  end
      
  class CounterMetric < Metric
  end
  
  class PercentageMetric < Metric
  end
  
  class AbsoluteMetric < Metric
  end
      
end