NAME = "dash-ruby"
AUTHOR = "FiveRuns Development Team"
EMAIL = "dev@fiveruns.com"
HOMEPAGE = "http://dash.fiveruns.com/"
SUMMARY = "Communication to the FiveRuns Dash service"

# Important: Make sure you modify this in version.rb, too
GEM_VERSION = '0.7.0'

Gem::Specification.new do |s|
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
  s.files = %w(Rakefile) + Dir.glob("{lib,test,recipes,examples}/**/*")
end