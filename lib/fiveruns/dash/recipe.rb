module Fiveruns::Dash
  
  class Recipe
    
    class ConfigurationError < ::ArgumentError; end
    
    attr_reader :name, :options
    def initialize(name, options = {}, &block)
      @name = name
      @options = options
      @block = block
      validate!
    end
    
    def add_to(configuration)
      @block.call(configuration)
    end
    
    #######
    private
    #######

    def validate!
      unless options[:url]
        raise ConfigurationError, "Recipe requires :url option"
      end
    end
    
  end
  
end