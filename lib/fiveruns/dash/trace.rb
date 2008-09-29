module Fiveruns::Dash
  
  class Trace
    
    attr_reader :context, :data, :stack
    def initialize(context)
      @context = context
      @stack = []
      validate!
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
      { :context => context,
        :data => (@data || {})
      }.to_json
    end
    
    private
    
    def validate!
      unless @context.is_a?(Array) && @context.size % 2 == 0
        raise ArgumentError, 'Invalid context: #{@context.inspect} (must be an array with an even number of elements)'
      end
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