module Fiveruns::Dash::Typable
    
  def self.included(base)
    name = Fiveruns::Dash::Util.shortname(base.name)
    base.class_eval %{
      def self.#{name}_type
        @#{name}_type ||= begin
          short = Fiveruns::Dash::Util.shortname(name)
          short.sub(/_#{name}$/, '').to_sym
        end
      end
    }
    base.extend ClassMethods
  end
  
  module ClassMethods
    
    def inherited(klass)
      types[klass.__send__("#{Fiveruns::Dash::Util.shortname(name)}_type")] = klass
    end

    def types
      @types ||= {}
    end
    
  end
  
end