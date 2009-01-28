require 'rake/testtask'

Rake::TestTask.new do |t|
  t.verbose = true
  t.test_files = FileList['test/*_test.rb']
end

task :default => :test

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