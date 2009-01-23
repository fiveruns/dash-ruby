Fiveruns::Dash.register_recipe :ruby, :url => 'http://dash.fiveruns.com' do |metrics|
  metrics.absolute :vsz, 
    "Virtual Memory Usage", "The amount of virtual memory used by this process", 
    :unit => 'kbytes', :scope => :host do 
    Integer(`ps -o vsz -p #{Process.pid}`[/(\d+)/, 1])
  end
  metrics.absolute :rss, "Resident Memory Usage", 
    "The amount of physical memory used by this process", 
    :unit => 'kbytes',
    :scope => :host do
    Integer(`ps -o rss -p #{Process.pid}`[/(\d+)/, 1])
  end
  metrics.percentage :pmem, 
  "Resident Memory Usage", 
  "Percentage of Resident Memory Usage", 
  :scope => :host do
    Float(`ps -o pmem -p #{Process.pid}`[/(\d+\.\d+)/, 1])
  end

  if RUBY_PLATFORM == 'java'
    Fiveruns::Dash.logger.warn "Cannot collect CPU usage data on JRuby"
  else
    metrics.percentage :cpu, 
      'CPU Usage', 
      'Percentage CPU Usage',
      :scope => :host do
      before = Thread.current[:dash_utime] ||= Process.times.utime
      after = Process.times.utime
      this_minute = after - before
      Thread.current[:dash_utime] = after
      (this_minute / 60) * 100.00
    end
  end
end
