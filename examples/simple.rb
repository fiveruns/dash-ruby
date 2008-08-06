require 'fileutils'

directory = File.expand_path(File.dirname(__FILE__) << "/tmp")
FileUtils.mkdir directory rescue nil
ENV['DASH_UPDATE'] = "file://#{directory}"

$:.unshift(File.dirname(__FILE__) << "/../lib")

require 'fiveruns/dash'

class MyApp
  
  def self.foos_last_minute(where)
    rand(80)
  end
  
  def do_something
    sleep 0.01
  end
  
end

class OtherApp < MyApp
end
  

Fiveruns::Dash.configure :app => 'foo-bar-baz' do |metrics|
  metrics.counter :foos, "Number of foos" do
    {
      [:place, 'here'] => MyApp.foos_last_minute(:here),
      [:place, 'there'] => MyApp.foos_last_minute(:there)
    }    
  end
  metrics.time :do_somethings, :method => 'MyApp#do_something', :contexts => lambda { |obj, *args| [:class, obj.class.name] }
  metrics.counter :somethings, :incremented_by => 'MyApp#do_something', :contexts => lambda { |obj, *args| [:class, obj.class.name] }
end
Fiveruns::Dash.configuration.metrics.each { |metric| metric.info_id = metric.name }
Fiveruns::Dash.session.reporter.interval = 10
Fiveruns::Dash.session.start

app = MyApp.new
other_app = OtherApp.new

loop do
  sleep rand(3)
  app.do_something
  other_app.do_something
end