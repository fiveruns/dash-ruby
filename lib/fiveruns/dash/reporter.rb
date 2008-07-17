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
      
      def revive!
        return if !started? || foreground?
        start if !@thread || !@thread.alive?
      end
      
      def start(run_in_background = true)
        restarted = @started ? true : false
        setup_for run_in_background
        if @background
          @thread = Thread.new { run(restarted) }
        else
          run(restarted)
        end
      end
      
      def started?
        @started
      end
      
      def foreground?
        started? && !@background
      end
      
      def background?
        started? && @background
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
      
      def setup_for(run_in_background = true)
        @started = true
        @background = run_in_background
      end
            
    end
    
  end
  
end