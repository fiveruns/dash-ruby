unless ENV['DASH_APP']
  abort 'Need DASH_APP (token)'
end

ENV['DASH_UPDATE'] = 'http://localhost:3000'

$:.unshift(File.dirname(__FILE__) << "/../lib")

require 'fiveruns/dash'