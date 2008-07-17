module Fiveruns
  
  module Dash
    
    class Session
      
      attr_reader :configuration
      def initialize(configuration)
        @configuration = configuration
      end
      
      def start
        loop do
          sleep 5
          p collect
        end
      end
      
      def collect
        configuration.metrics.inject({}) do |metrics, metric|
          metrics[metric.name] = metric.current_value
          metrics
        end
      end
      
    end
    
  end
  
end