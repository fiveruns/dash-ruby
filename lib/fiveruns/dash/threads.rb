require 'thread'

module Fiveruns::Dash
  
  module Threads
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      def mutex
        @mutex ||= Mutex.new
      end
      
      def sync(&block)
        mutex.synchronize(&block)
      end
      
    end
    
  end
  
end