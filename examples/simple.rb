require File.dirname(__FILE__) << "/example_helper"

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

Fiveruns::Dash.start :app => 'foo-bar-baz' do |metrics|
  metrics.counter :foos, "BAR!" do
    MyApp.foos_last_minute
  end
  metrics.time 'MyApp#do_something'
end

app = MyApp.new

loop do
  sleep rand(3)
  app.do_something
end