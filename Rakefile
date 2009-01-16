require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'

require File.dirname(__FILE__) << "/lib/fiveruns/dash/version"

NAME = "fiveruns_dash"
AUTHOR = "FiveRuns Development Team"
EMAIL = "dev@fiveruns.com"
HOMEPAGE = "http://dash.fiveruns.com/"
SUMMARY = "Communication to the FiveRuns Dash service"
GEM_VERSION = Fiveruns::Dash::Version::STRING

spec = Gem::Specification.new do |s|
  s.rubyforge_project = 'fiveruns'
  s.name = NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = %w()
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  # a bug in json_pure 1.1.3 prevents us from using the pure Ruby version.
  s.add_dependency('json')
  s.require_path = 'lib'
  s.files = %w(Rakefile) + FileList["{lib,test,recipes,examples}/**/*"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

Rake::TestTask.new do |t|
  t.verbose = true
  t.test_files = FileList['test/*_test.rb']
end

task :default => :test

sudo = RUBY_PLATFORM[/win/] ? '' : 'sudo '

desc "Install as a gem"
task :install => [:package, :uninstall] do
  sh %{#{sudo}gem install pkg/#{NAME}-#{GEM_VERSION} --no-update-sources}
end

desc "Uninstall the gem"
task :uninstall do
  sh %{#{sudo}gem uninstall #{NAME} -aIxv #{GEM_VERSION}} rescue nil
end

namespace :jruby do

  desc "Run :package and install the resulting .gem with jruby"
  task :install => [:package, 'jruby:uninstall'] do
    sh %{#{sudo}jruby -S gem install #{install_home} pkg/#{NAME}-#{GEM_VERSION}.gem --no-rdoc --no-ri}
  end
  
  desc "Uninstall the gem"
  task :uninstall do
    sh %{#{sudo}jruby -S gem uninstall #{NAME} -aIxv #{GEM_VERSION}} rescue nil
  end
  
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

task :cruise => [:test, :coverage]