require 'fileutils'

directory = File.expand_path(File.dirname(__FILE__) << "/tmp")
FileUtils.mkdir directory rescue nil
ENV['DASH_UPDATE'] = "file://#{directory}"

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
  metrics.time :do_somethings, :method => 'MyApp#do_something'
end

app = MyApp.new

loop do
  sleep rand(3)
  app.do_something
end