class Fiveruns::Dash::Application
  
  MODES = {'r' => :read, 'w' => :write}
  
  attr_reader :mode
  def initialize(mode, options = {})
    @mode = MODES[mode.to_s[0,1]]
    configure(options) unless options.empty?
  end
  
  def configuration
    @configuration ||= mode_class(:configuration).new(self)
  end
  
  def configure(options = {}, &block)
    configuration.update(options)
    yield configuration if block_given?
  end
  
  def token
    configuration.token
  end
  
  def session
    @session ||= mode_class(:session).new(self)
  end
  
  def validate!
    unless token
      raise ArgumentError, "Dash has not been configured with a #{@mode.to_s.capitalize} Token" 
    end
  end
  
  private
  
  def mode_class(name)
    name = "Fiveruns::Dash::#{@mode.to_s.capitalize}::#{name.to_s.capitalize}"
    Fiveruns::Dash::Util.constantize(name)
  end

end