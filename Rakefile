require 'rake/testtask'

Rake::TestTask.new do |t|
  t.verbose = true
  t.test_files = FileList['test/*_test.rb']
end

task :default => :test

begin 
  require 'jeweler' 

  Jeweler::Tasks.new do |s| 
    s.name = "dash-ruby" 
    s.rubyforge_project = 'fiveruns'
    s.summary = "FiveRuns Dash core library for Ruby" 
    s.email = "dev@fiveruns.com" 
    s.homepage = "http://github.com/fiveruns/dash-ruby" 
    s.description = "Provides an API to send metrics to the FiveRuns Dash service" 
    s.authors = ["FiveRuns Development Team"] 
    s.files =  FileList['README.markdown', 'Rakefile', 'version.yml', "{lib,test,recipes,examples}/**/*", ] 
  end 
rescue LoadError 
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com" 
end

task :coverage do
  rm_f "coverage"
  rm_f "coverage.data"
  rcov = "rcov --exclude gems --exclude version.rb --sort coverage --text-summary --html -o coverage"
  system("#{rcov} test/*_test.rb")
  if ccout = ENV['CC_BUILD_ARTIFACTS']
    FileUtils.rm_rf '#{ccout}/coverage'
    FileUtils.cp_r 'coverage', ccout
  end
  system "open coverage/index.html" if PLATFORM['darwin']
end
