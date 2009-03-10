module Fiveruns::Dash::Write::Context
  def self.set(value)
    Thread.current[:fiveruns_dash_context] = value
  end

  def self.reset
    Thread.current[:fiveruns_dash_context] = []
  end

  def self.context
    Thread.current[:fiveruns_dash_context] ||= []
  end
end