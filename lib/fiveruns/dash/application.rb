class Fiveruns::Dash::Application
  
  MODES = {'r' => :read, 'w' => :write}
  
  attr_reader :token, :mode
  def initialize(token, mode = 'w')
    @token = token
    @mode = MODES[mode.to_s[0,1]]
    validate!
  end
  
  private
  
  def validate!
    unless @mode
      raise ArgumentError, "Invalid mode; must be one of #{MODES.values.inspect}"
    end
    unless @token
      raise ArgumentError, "#{MODES[@mode].capitalize} Token required"
    end
  end

end