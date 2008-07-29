Fiveruns::Dash.register_recipe :ruby do |metrics|
  metrics.absolute :rmem, "Resident Memory", :unit => 'byte' do 
    Integer(`ps -o rss -p #{Process.pid}`[/(\d+)/, 1])
  end
end