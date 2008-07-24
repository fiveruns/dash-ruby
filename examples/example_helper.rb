unless ENV['DASH_APP']
  abort 'Need DASH_APP (token)'
end

ENV['DASH_UPDATE'] = 'http://localhost:3000'

$:.unshift(File.dirname(__FILE__) << "/../lib")

require 'fiveruns/dash'

def dash(&block)
  Fiveruns::Dash.configure({:app => ENV['DASH_APP']}, &block)
  Fiveruns::Dash.session.reporter.interval = 10
  Fiveruns::Dash.session.start
end