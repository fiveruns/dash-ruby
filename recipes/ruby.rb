Fiveruns::Dash.register_recipe :ruby, :url => 'http://dash.fiveruns.com' do |metrics|
  metrics.absolute :rss, "Resident Memory", :unit => 'byte' do 
    Integer(`ps -o rss -p #{Process.pid}`[/(\d+)/, 1])
  end
  metrics.absolute :pmem, "Resident Memory" do 
    Float(`ps -o pmem -p #{Process.pid}`[/(\d+\.\d+)/, 1])
  end  
  metrics.percentage :cpu, 'CPU Usage' do
    (Process.times.utime / ::Fiveruns::Dash.process_age) * 100.00
  end
end