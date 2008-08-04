Fiveruns::Dash.register_recipe :ruby, :url => 'http://dash.fiveruns.com' do |metrics|
  metrics.absolute :rmem, "Resident Memory", :unit => 'byte' do 
    Integer(`ps -o rss -p #{Process.pid}`[/(\d+)/, 1])
  end
end