require 'rubygems'
require 'echoe'

require File.dirname(__FILE__) << "/lib/fiveruns/dash/version"

Echoe.new 'fiveruns_dash' do |p|
  p.version = Fiveruns::Dash::Version::STRING
  p.author = "FiveRuns Development Team"
  p.email  = 'dev@fiveruns.com'
  p.project = 'fiveruns'
  p.summary = "Communication to the FiveRuns Dash service"
  p.url = "http://dash.fiveruns.com"
  p.include_rakefile = true
#  p.runtime_dependencies = %w(activesupport json_pure)
  p.runtime_dependencies = %w(activesupport json)
  p.development_dependencies = %w(FakeWeb Shoulda)
  p.rcov_options = '--exclude gems --exclude version.rb --sort coverage --text-summary --html -o coverage'
end

task :coverage do
  if ccout = ENV['CC_BUILD_ARTIFACTS']
    FileUtils.rm_rf '#{ccout}/coverage'
    FileUtils.cp_r 'coverage', ccout
  end
  system "open coverage/index.html" if PLATFORM['darwin']
end

task :cruise => [:test, :coverage]
