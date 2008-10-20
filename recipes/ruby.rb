Fiveruns::Dash.register_recipe :ruby, :url => 'http://dash.fiveruns.com' do |metrics|
  metrics.absolute :rss, "Resident Memory Usage", "The Absolute Resident Memory Usage", :unit => 'bytes', :aggregate => {:host => :sum, :app => :average} do 
    Integer(`ps -o rss -p #{Process.pid}`[/(\d+)/, 1])
  end
  metrics.percentage :pmem, "Resident Memory Usage", "The Percentage Resident Memopry Usage", :aggregate => {:host => :sum, :app => :average} do 
    Float(`ps -o pmem -p #{Process.pid}`[/(\d+\.\d+)/, 1])
  end  
  metrics.percentage :cpu, 'CPU Usage', 'Percentage CPU Usage', :aggregate => {:host => :sum, :app => :average} do
    (Process.times.utime / ::Fiveruns::Dash.process_age) * 100.00
  end
end