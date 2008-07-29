require 'dash/typable'

module Fiveruns::Dash

  # Can't override :unit option
  module LockedUnit
    def unit_info
      raise ArgumentError, "Can not set :unit for `#{@name}' #{self.class.metric_type} metric" if @options[:unit]
      {}
    end
  end
        
  class Metric
    include Typable
    
    attr_reader :name, :description, :options
    attr_accessor :info_id
    def initialize(name, *args, &block)
      @name = name.to_s
      @options = args.extract_options!
      @description = args.shift || @name.titleize
      @operation = block
    end
    
    def info
      {name => {:data_type => self.class.metric_type, :description => description}.merge(unit_info)}
    end
    
    def data
      if info_id
        value_hash.update(:metric_info_id => info_id)
      else
        raise NotImplementedError, "No info_id assigned for #{self.inspect}"
      end
    end

    #######
    private
    #######
    
    def unit_info
       @options[:unit] ? {:unit => @options[:unit].to_s} : {}
    end
    
    def value_hash
      {:value => @operation.call}
    end
    
  end
  
  class TimeMetric < Metric
    include LockedUnit
    
    def initialize(*args)
      super(*args)
      reset
      install_hook
    end
    
    #######
    private
    #######
    
    def value_hash
      returning(:value => @time, :invocations => @invocations) do
        reset
      end
    end
    
    def reset
      @invocations = @time = 0
    end

    def install_hook
      if methods_to_instrument.blank?
        raise ArgumentError, "Must set :method or :methods option for `#{@name}` time metric"
      end
      methods_to_instrument.each do |meth|
        Instrument.add meth do |obj, time, *args|
          @invocations += 1
          @time += time
        end
      end
    end
    
    def methods_to_instrument
      @methods_to_instrument ||= Array(@options[:method]) + Array(@options[:methods])
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
        returning(:value => @invocations) do
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
      incrementing_methods.each do |meth|
        Instrument.add meth do |*args|
          @invocations += 1
        end
      end
    end
    
    def reset
      @counter = 0
    end     
    
    def incrementing_methods
      @incrementing_methods ||= Array(@options[:incremented_by])
    end
    
  end
  
  class PercentageMetric < Metric
    include LockedUnit
  end
  
  class AbsoluteMetric < Metric
  end
      
end