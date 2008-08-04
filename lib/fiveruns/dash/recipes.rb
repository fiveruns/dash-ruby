module Fiveruns::Dash
  
  module Recipes
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      def register_recipe(name, &block)
        recipes[name] ||= []
        recipes[name] << block
      end

      def recipes
        @recipes ||= {}
      end
      
      def load_recipes
        Dir[File.dirname(__FILE__) << "/../../../recipes/*.rb"].each do |file|
          require file
        end
      end
      
    end
    
  end
  
end