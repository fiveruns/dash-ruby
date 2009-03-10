class Fiveruns::Dash::Application
  
  MODES = {'r' => :read, 'w' => :write}
  
  attr_reader :token, :mode
  def initialize(token, mode = 'w')
    @token = token
    @mode = MODES[mode.to_s[0,1]]
    validate!
  end
  
  def session
    @session ||= session_class.new(self)
  end
  
  private
  
  def session_class
    name = "Fiveruns::Dash::#{@mode.to_s.capitalize}::Session"
    Fiveruns::Dash::Util.constantize(name)
  end
  
  def validate!
    unless @mode
      raise ArgumentError, "Invalid mode; must be one of #{MODES.values.inspect}"
    end
    unless @token
      raise ArgumentError, "#{@mode.to_s.capitalize} Token required"
    end
  end

end