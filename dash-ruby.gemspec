# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dash-ruby}
  s.version = "0.7.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["FiveRuns Development Team"]
  s.date = %q{2009-02-02}
  s.description = %q{Provides an API to send metrics to the FiveRuns Dash service}
  s.email = %q{dev@fiveruns.com}
  s.files = ["README.rdoc", "Rakefile", "version.yml", "lib/fiveruns", "lib/fiveruns/dash", "lib/fiveruns/dash/configuration.rb", "lib/fiveruns/dash/exception_recorder.rb", "lib/fiveruns/dash/host.rb", "lib/fiveruns/dash/instrument.rb", "lib/fiveruns/dash/metric.rb", "lib/fiveruns/dash/recipe.rb", "lib/fiveruns/dash/reporter.rb", "lib/fiveruns/dash/scm.rb", "lib/fiveruns/dash/session.rb", "lib/fiveruns/dash/store", "lib/fiveruns/dash/store/file.rb", "lib/fiveruns/dash/store/http.rb", "lib/fiveruns/dash/threads.rb", "lib/fiveruns/dash/trace.rb", "lib/fiveruns/dash/typable.rb", "lib/fiveruns/dash/update.rb", "lib/fiveruns/dash/version.rb", "lib/fiveruns/dash.rb", "test/collector_communication_test.rb", "test/configuration_test.rb", "test/exception_recorder_test.rb", "test/file_store_test.rb", "test/fixtures", "test/fixtures/http_store_test", "test/fixtures/http_store_test/response.json", "test/http_store_test.rb", "test/metric_test.rb", "test/recipe_test.rb", "test/reliability_test.rb", "test/reporter_test.rb", "test/scm_test.rb", "test/session_test.rb", "test/test_helper.rb", "test/tracing_test.rb", "test/update_test.rb", "recipes/jruby.rb", "recipes/ruby.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/fiveruns/dash-ruby}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{fiveruns}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{FiveRuns Dash core library for Ruby}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 0"])
    else
      s.add_dependency(%q<json>, [">= 0"])
    end
  else
    s.add_dependency(%q<json>, [">= 0"])
  end
end
