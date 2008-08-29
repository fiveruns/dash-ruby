Fiveruns::Dash.register_recipe :ruby, :url => 'http://dash.fiveruns.com' do |metrics|
  metrics.absolute :rss, "Resident Memory", :unit => 'byte', :aggregate => :average do 
    Integer(`ps -o rss -p #{Process.pid}`[/(\d+)/, 1])
  end
  metrics.percentage :pmem, "Resident Memory", :aggregate => :average do 
    Float(`ps -o pmem -p #{Process.pid}`[/(\d+\.\d+)/, 1])
  end  
  metrics.percentage :cpu, 'CPU Usage', :aggregate => :sum do
    (Process.times.utime / ::Fiveruns::Dash.process_age) * 100.00
  end
end