module Fiveruns::Dash::Logging
  
  def logger
    @logger ||= begin
      # TODO: Make dash-rails handle this if it doesn't already -BW
      if defined?(RAILS_DEFAULT_LOGGER) 
        RAILS_DEFAULT_LOGGER
      else
        Logger.new(STDOUT)
      end
    end
  end

  def logger=(logger)
    @logger = logger
  end
  
end