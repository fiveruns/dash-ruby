module Fiveruns::Dash
  
  class Trace
    
    attr_reader :name, :data, :stack
    def initialize(name)
      @name = name
      @stack = []
    end
    
    def step(&block)
      s = Step.new
      @stack.last.children << s if !@stack.empty?
      @stack << s
      result = yield
      last_step = @stack.pop
      @data = last_step if @stack.empty?
      result
    end
        
    def add_data(metric, contexts, value)
      unless @stack.empty?
        @stack.last.metrics.push(
          :info_id => metric.info_id,
          :contexts => contexts,
          :value => value
        )
      end
    end
        
    def to_json
      { :name => name,
        :data => (@data || {})
      }.to_json
    end
    
    class Step
                  
      def metrics
        @metrics ||= []
      end
      
      def children
        @children ||= []
      end
            
      def to_json
        {
          :metrics => metrics,
          :children => children,
        }.to_json
      end
      
    end
    
  end
  
end