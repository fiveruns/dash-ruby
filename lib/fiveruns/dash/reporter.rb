require 'thread'

Thread.abort_on_exception = true

module Fiveruns::Dash
    
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

    def run(restarted)
      loop do
        send_info_update
        sleep @interval
        send_data_update
      end
    end
    
    def setup_for(run_in_background = true)
      @started = true
      @background = run_in_background
    end
    
    def send_info_update
      @info_update_sent ||= begin
        payload = InfoPayload.new(@session.info)
        Update.new(payload, @session.configuration).store(*update_locations)
      end
    end
    
    def send_data_update
      if @info_update_sent
        payload = DataPayload.new(@session.data)
        Update.new(payload, @session.configuration).store(*update_locations)
      else
        # Discard data
        @session.data
        Fiveruns::Dash.logger.warn "Discarding interval data"
      end
    end
    
    def update_locations
      @update_locations ||= if ENV['DASH_UPDATE']
        ENV['DASH_UPDATE'].strip.split(/\s*,\s*/)
      else
        default_update_locations
      end
    end
    
    def default_update_locations
      %w(https://dash-collector.fiveruns.com https://dash-collector02.fiveruns.com)
    end
          
  end
      
end