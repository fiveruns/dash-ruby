unless ENV['DASH_APP']
  abort 'Need DASH_APP (token)'
end

ENV['DASH_UPDATE'] = 'http://localhost:3000'

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

Fiveruns::Dash.configure :app => ENV['DASH_APP'] do |metrics|
  metrics.counter :foos, "BAR!" do
    MyApp.foos_last_minute
  end
  metrics.time 'MyApp#do_something'
end
Fiveruns::Dash.session.reporter.interval = 10
Fiveruns::Dash.session.start

app = MyApp.new

loop do
  sleep rand(3)
  app.do_something
end