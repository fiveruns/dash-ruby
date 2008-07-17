$:.unshift(File.dirname(__FILE__) << "/../lib")

require 'fiveruns/dash'

module MyApp
  def self.foos_last_minute
    rand(80)  
  end
end

Fiveruns::Dash.configure :app => 'foo-bar-baz' do |metrics|
  metrics.counter :foos, "BAR!" do
    MyApp.foos_last_minute
  end
end

Fiveruns::Dash.start