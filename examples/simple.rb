$:.unshift(File.dirname(__FILE__) << "/../lib")

require 'fiveruns/dash'

class MyApp
  
  def self.foos_last_minute
    rand(80)  
  end
  
  def do_something
    sleep 0.01
  end
  
end

Fiveruns::Dash.configure :app => 'foo-bar-baz' do |metrics|
  metrics.counter :foos, "BAR!" do
    MyApp.foos_last_minute
  end
  metrics.time 'MyApp#do_something'
end

Thread.new do
  Fiveruns::Dash.start
end

app = MyApp.new

loop do
  sleep rand(3)
  app.do_something
end