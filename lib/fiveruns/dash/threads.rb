require 'thread'

module Fiveruns::Dash
  
  module Threads
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      def monitor
        @monitor ||= Monitor.new
      end
      
      def sync(&block)
        monitor.synchronize(&block)
      end
    end
    
  end
  
end