require 'dash/typable'

module Fiveruns::Dash
          
  class Metric
    include Typable
    
    attr_reader :name, :description, :options
    attr_accessor :info_id, :recipe
    def initialize(name, *args, &block)
      @name = name.to_s
      @options = args.extract_options!
      @description = args.shift || @name.titleize
      @operation = block
      validate!
    end
    
    def info
      {key => {:data_type => self.class.metric_type, :description => description}.merge(unit_info)}
    end
        
    def data
      if info_id
        value_hash.update(:metric_info_id => info_id)
      else
        raise NotImplementedError, "No info_id assigned for #{self.inspect}"
      end
    end
    
    def reset
      # Abstract
    end
    
    def key
      @key ||= {
        :name => name,
        :recipe_url => recipe ? recipe.url : nil,
        :recipe_name => recipe ? recipe.name.to_s : nil
      }
    end
    
    def ==(other)
      key == other.key
    end
    
    # Set context finder
    def find_context_with(&block)
      @context_finder = block
    end
    
    #######
    private
    #######
    
    def validate!
      true
    end
    
    def unit_info
       @options[:unit] ? {:unit => @options[:unit].to_s} : {}
    end
    
    def value_hash
      current_value = ::Fiveruns::Dash.sync { @operation.call }
      {:values => parse_value(current_value)}
    end
    
    # Verifies value matches one of the following patterns:
    # * A numeric value (indicates no namespace)
    # * A hash of [namespace_kind, namespace_name, ...] => value pairs, eg:
    #     [:controller, 'FooController', :action, 'bar'] => 12
    def parse_value(value)
      case value
      when Numeric
        value
      when Hash
        value.inject([]) do |all, (key, val)|
          case key
          when nil
            all.push :context => nil, :value => val
          when Array
            if key.size % 2 == 0
              all.push :context => key, :value => val
            else
              bad_value! "Contexts must have an even number of items"
            end
          else
            bad_value! "Unknown context type"
          end
          all
        end
      else
        bad_value! "Unknown value type"
      end
    end
    
    def bad_value!(message)
      raise ArgumentError, "Bad data for `#{@name}' #{self.class.metric_type} metric: #{message}"
    end
    
    # Note: only to be used when the +@operation+
    #       block is used to set contexts
    def find_containers(*args, &block) #:nodoc:
      contexts = Array(current_context_for(*args))
      if contexts.empty? || contexts == [[]]
        contexts = [nil]
      elsif contexts.all? { |item| !item.is_a?(Array) }
        contexts = [contexts]
      end
      contexts.each do |context|
        with_container_for_context(context, &block)
      end
    end
    
    # Get the container for this context, allow modifications to it,
    # and store it
    # * Note: We sync here when looking up the container, while
    #         the block is being executed, and when it is stored
    def with_container_for_context(context)
      ::Fiveruns::Dash.sync do
        container = @data[context]
        new_container = yield container
        @data[context] = new_container # For hash defaults
      end
    end
    
    def context_finder
      @context_finder ||= begin
        context_setting = @options[:context] || @options[:contexts]
        context_setting.is_a?(Proc) ? context_setting : lambda { |*args| Array(context_setting) } 
      end
    end
    
    # Retrieve the context for the given arguments
    # * Note: We need to sync here (and wherever the context is modified)
    def current_context_for(*args)
      ::Fiveruns::Dash.sync { context_finder.call(*args) }
    end
    
  end
  
  class TimeMetric < Metric
    
    def initialize(*args)
      super(*args)
      reset
      install_hook
    end
    
    def reset
      ::Fiveruns::Dash.sync do
        @data = Hash.new {{ :invocations => 0, :value => 0 }}
      end
    end
    
    #######
    private
    #######
    
    def value_hash
      returning(:values => current_value) do
        reset
      end
    end

    def install_hook
      @operation ||= lambda { nil }
      methods_to_instrument.each do |meth|
        Instrument.add meth do |obj, time, *args|
          find_containers(obj, *args) do |container|
            container[:invocations] += 1
            container[:value] += time
            container
          end
        end
      end
    end
    
    def methods_to_instrument
      @methods_to_instrument ||= Array(@options[:method]) + Array(@options[:methods])
    end
    
    def validate!
      raise ArgumentError, "Can not set :unit for `#{@name}' time metric" if @options[:unit]
      if methods_to_instrument.blank?
        raise ArgumentError, "Must set :method or :methods option for `#{@name}` time metric"
      end
    end
    
    # Get the current value
    # * Note: We sync here (and wherever @data is being written)
    def current_value
      ::Fiveruns::Dash.sync do
        @data.inject([]) do |all, (context, data)|
          all.push(data.merge(:context => context))
        end
      end
    end
    
  end
      
  class CounterMetric < Metric
    
    def initialize(*args)
      super(*args)
      if incrementing_methods.any?
        reset
        install_hook
      end
    end
    
    def value_hash
      if incrementing_methods.any?
        returning(:values => current_value) do
          reset
        end
      else
        super
      end
    end
    
    def install_hook
      if incrementing_methods.blank?
        raise RuntimeError, "Bad configuration for `#{@name}` counter metric"
      end
      @operation ||= lambda { nil }
      incrementing_methods.each do |meth|
        Instrument.add meth do |obj, time, *args|
          find_containers(obj, *args) do |container|
            container += 1
            container
          end
        end
      end
    end
    
    # Reset the current value
    # * Note: We sync here (and wherever @data is being written)
    def reset
      ::Fiveruns::Dash.sync { @data = Hash.new(0) }
    end     
    
    def incrementing_methods
      @incrementing_methods ||= Array(@options[:incremented_by])
    end
    
    def validate!
      if !@options[:incremented_by]
        raise ArgumentError, "No block given to capture counter `#{@name}'" unless @operation
      end
    end
    
    # Get the current value
    # * Note: We sync here (and wherever @data is being written)
    def current_value
      result = ::Fiveruns::Dash.sync do
        # Ensure the nil context is stored with a default of 0
        @data[nil] = @data.fetch(nil, 0)
        @data
      end
      parse_value result
    end
    
  end
  
  class PercentageMetric < Metric
    
    def validate!
      raise ArgumentError, "Can not set :unit for `#{@name}' percentage metric" if @options[:unit]
    end
      
  end
  
  class AbsoluteMetric < Metric
  end
      
end