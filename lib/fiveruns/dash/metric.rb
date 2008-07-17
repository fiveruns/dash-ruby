module Fiveruns
  
  module Dash
    
    class Metric
            
      def self.inherited(klass)
        types[klass.metric_type] = klass
      end
      
      def self.types
        @types ||= {}
      end
      
      attr_reader :name, :description
      def initialize(name, description = name.to_s.titleize, &block)
        @name = name
        @description = description
        @operation = block
      end
      
      def current_value
        @operation.call
      end

      #######
      private
      #######
      
      def self.metric_type
        @metric_type ||= name.demodulize.underscore.sub(/_metric$/, '').to_sym
      end
      
    end
    
    class TimeMetric < Metric
      
      def initialize(name, description)
        raise NotImplementedError, 'TODO'
      end
      
    end
        
    class CounterMetric < Metric
    end
    
    class PercentageMetric < Metric
    end
    
    class AbsoluteMetric < Metric
    end
    
  end
  
end