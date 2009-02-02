require 'dash/typable'

module Fiveruns::Dash
          
  class Metric
    include Typable
    
    attr_reader :name, :description, :help_text, :options
    attr_accessor :recipe
    def initialize(name, *args, &block)
      @@warned = false
      @name = name.to_s
      @options = args.extract_options!
      @description = args.shift || @name.titleize
      @help_text = args.shift
      @operation = block
      @virtual = !!options[:sources]
      @abstract = options[:abstract]
      validate!
    end

    # Indicates that this metric is calculated based on the value(s)
    # of other metrics.
    def virtual?
      @virtual
    end

    # Indicates that this metric is only used for virtual calculations
    # and should not be sent to the server for storage.
    def abstract?
      @abstract
    end

    def data
      return nil if virtual?
      value_hash.merge(key)
    end
    
    def calculate(real_data)
      return nil unless virtual?

      datas = options[:sources].map {|met_name| real_data.detect { |hash| hash[:name] == met_name } }.compact

      if datas.size != options[:sources].size && options[:sources].include?('response_time')
        Fiveruns::Dash.logger.warn(<<-LOG
          ActiveRecord utilization metrics require a time metric so Dash can calculate a percentage of time spent in the database.
          Please set the :ar_total_time option when configuring Dash:

          # Define an application-specific metric cooresponding to the total processing time for this app.
          Fiveruns::Dash.register_recipe :loader, :url => 'http://dash.fiveruns.com' do |recipe|
            recipe.time :total_time, 'Load Time', :method => 'Loader::Engine#load'
          end

          # Pass the name of this custom metric to Dash so it will be used in the AR metric calculations.
          Fiveruns::Dash.configure :app => token, :ar_total_time => 'total_time' do |config|
            config.add_recipe :activerecord
            config.add_recipe :loader, :url => 'http://dash.fiveruns.com'
          end
        LOG
        ) unless @@warned
        @@warned = true
        return nil
      else
        raise ArgumentError, "Could not find one or more of #{options[:sources].inspect} in #{real_data.map { |h| h[:name] }.inspect}" unless datas.size == options[:sources].size
      end

      combine(datas.map { |hsh| hsh[:values] }).merge(key)
    end

    def reset
      # Abstract
    end
    
    def info
      key
    end
    
    def key
      @key ||= begin
        {
          :name => name,
          :recipe_url => recipe ? recipe.url : nil,
          :recipe_name => recipe ? recipe.name.to_s : nil,
          :data_type => self.class.metric_type, 
          :description => description, 
          :help_text => help_text,
        }.merge(optional_info)
      end
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
      raise ArgumentError, "#{name} - Virtual metrics should have source metrics" if virtual? && options[:sources].blank?
      raise ArgumentError, "#{name} - metrics should not have source metrics" if !virtual? && options[:sources]
    end
    
    def optional_info
      returning({}) do |optional|
        copy = optional.merge(@options[:unit] ? {:unit => @options[:unit].to_s} : {})
        copy = copy.merge(@options[:scope] ? {:scope => @options[:scope].to_s} : {})        
        copy = copy.merge(abstract? ? {:abstract => true} : {})
        optional.merge!(copy)
      end
    end

    def combine(source_values)
      # Get the intersection of contexts for all the source metrics.
      # We combine the values for all shared contexts.
      contexts = source_values.map { |values| values.map { |value| value[:context] }}
      intersection = nil
      contexts.each_with_index do |arr, idx|
        if idx == 0
          intersection = arr
        else
          intersection = intersection & arr
        end
      end

      values = intersection.map do |context|
        args = source_values.map do |values|
          values.detect { |value| value[:context] == context }[:value]
        end

        { :value => @operation.call(*args), :context => context }
      end

      {:values => values}
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
        [{:context => [], :value => value}]
      when Hash
        value.inject([]) do |all, (key, val)|
          case key
          when nil
            all.push :context => [], :value => val
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
        contexts = [[]]
      elsif contexts.all? { |item| !item.is_a?(Array) }
        contexts = [contexts]
      end
      if Thread.current[:trace]
        result = yield blank_data[[]]
        Thread.current[:trace].add_data(self, contexts, result)
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
      ctx = (context || []).dup # normalize nil context to empty
      ::Fiveruns::Dash.sync do
        container = @data[ctx]
        new_container = yield container
        #Fiveruns::Dash.logger.info "#{name}/#{context.inspect}/#{new_container.inspect}"
        @data[ctx] = new_container # For hash defaults
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
        @data = blank_data
      end
    end
    
    #######
    private
    #######
    
    def blank_data
      Hash.new {{ :invocations => 0, :value => 0 }}
    end
    
    def value_hash
      returning(:values => current_value) do
        reset
      end
    end

    def install_hook
      @operation ||= lambda { nil }
      methods_to_instrument.each do |meth|
        Instrument.add meth, instrument_options do |obj, time, *args|
          find_containers(obj, *args) do |container|
            container[:invocations] += 1
            container[:value] += time
            container
          end
        end
      end
    end
    
    def instrument_options
      returning({}) do |options|
        options[:reentrant_token] = self.object_id.abs if @options[:reentrant]
      end
    end

    def methods_to_instrument
      @methods_to_instrument ||= Array(@options[:method]) + Array(@options[:methods])
    end
    
    def validate!
      super
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
      ::Fiveruns::Dash.sync { @data = blank_data }
    end
    
    def blank_data
      Hash.new(0)
    end
    
    def incrementing_methods
      @incrementing_methods ||= Array(@options[:incremented_by])
    end
    
    def validate!
      super
      if !@options[:incremented_by]
        raise ArgumentError, "No block given to capture counter `#{@name}'" unless @operation
      end
    end
    
    # Get the current value
    # * Note: We sync here (and wherever @data is being written)
    def current_value
      result = ::Fiveruns::Dash.sync do
        # Ensure the empty context is stored with a default of 0
        @data[[]] = @data.fetch([], 0)
        @data
      end
      parse_value result
    end
    
  end
  
  class PercentageMetric < Metric
    
    def validate!
      super
      raise ArgumentError, "Can not set :unit for `#{@name}' percentage metric" if @options[:unit]
    end
      
  end
  
  class AbsoluteMetric < Metric
  end
      
end
