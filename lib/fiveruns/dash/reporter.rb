require 'thread'

Thread.abort_on_exception = true

module Fiveruns
  
  module Dash
    
    class Reporter
      
      attr_accessor :interval
      def initialize(session, interval = 60.seconds.to_i)
        @session = session
        @interval = interval
      end
      
      def started?
        @started
      end
      
      def foreground?
        @background == false
      end
      
      def background?
        @background
      end
      
      def revive!
        return if !started? || foreground?
        start if !@thread || !@thread.alive?
      end
      
      def start(background = true)
        restarted = @started ? true : false
        @started = true
        @background = background
        if background
          @thread = Thread.new { run(restarted) }
        else
          run(restarted)
        end
      end
      
      #######
      private
      #######

      # FIXME
      def run(restarted)
        p @session.info unless restarted
        loop do
          sleep @interval
          p @session.data
        end
      end
            
    end
    
  end
  
end