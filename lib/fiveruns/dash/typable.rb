module Fiveruns::Dash
  
  module Typable
    
    def self.included(base)
      name = base.name.demodulize.underscore
      base.class_eval %{
        def self.#{name}_type
          @#{name}_type ||= name.demodulize.underscore.sub(/_#{name}$/, '').to_sym
        end
      }
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      def inherited(klass)
        types[klass.__send__("#{name.demodulize.underscore}_type")] = klass
      end

      def types
        @types ||= {}
      end
      
    end
    
  end
  
end