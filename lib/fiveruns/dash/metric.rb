require 'dash/typable'

module Fiveruns::Dash
      
  class Metric
    include Typable
    
    attr_reader :family, :name, :description
    def initialize(family, name, description = name.to_s, &block)
      @family = family
      @name = name.to_s
      @description = description
      @operation = block
    end
    
    def info
      if @family == :custom
        {name => {:type => self.class.metric_type, :description => description}}
      else
        {}
      end
    end
    
    def data
      # TODO: Migrate :type being passed on every request to an Info lookup
      add_value_to(:type => self.class.metric_type, :family => @family, :name => @name)
    end

    #######
    private
    #######
    
    def add_value_to(hash)
      hash.update(:value => @operation.call)
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
    
    def add_value_to(hash)
      returning hash.update(:value => @time, :invocations => @invocations) do
        reset
      end
    end
    
    def reset
      @invocations = @time = 0
    end

    def install_hook
      instrument name do |obj, time, *args|
        @invocations += 1
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