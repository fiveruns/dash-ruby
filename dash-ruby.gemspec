# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{fiveruns-dash-ruby}
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["FiveRuns Development Team"]
  s.date = %q{2009-03-10}
  s.description = %q{Provides an API to send metrics to the FiveRuns Dash service}
  s.email = %q{dev@fiveruns.com}
  s.files = ["README.rdoc", "Rakefile", "version.yml", "lib/fiveruns", "lib/fiveruns/dash", "lib/fiveruns/dash/application.rb", "lib/fiveruns/dash/host.rb", "lib/fiveruns/dash/logging.rb", "lib/fiveruns/dash/read", "lib/fiveruns/dash/read.rb", "lib/fiveruns/dash/typable.rb", "lib/fiveruns/dash/util.rb", "lib/fiveruns/dash/version.rb", "lib/fiveruns/dash/write", "lib/fiveruns/dash/write/configuration.rb", "lib/fiveruns/dash/write/context.rb", "lib/fiveruns/dash/write/exception_recorder.rb", "lib/fiveruns/dash/write/instrument.rb", "lib/fiveruns/dash/write/metric.rb", "lib/fiveruns/dash/write/recipe.rb", "lib/fiveruns/dash/write/reporter.rb", "lib/fiveruns/dash/write/scm.rb", "lib/fiveruns/dash/write/session.rb", "lib/fiveruns/dash/write/store", "lib/fiveruns/dash/write/store/file.rb", "lib/fiveruns/dash/write/store/http.rb", "lib/fiveruns/dash/write/store.rb", "lib/fiveruns/dash/write/update.rb", "lib/fiveruns/dash/write.rb", "lib/fiveruns/dash.rb", "lib/fiveruns/json", "lib/fiveruns/json/add", "lib/fiveruns/json/add/core.rb", "lib/fiveruns/json/add/rails.rb", "lib/fiveruns/json/common.rb", "lib/fiveruns/json/generator.rb", "lib/fiveruns/json/parser.rb", "lib/fiveruns/json/pure.rb", "lib/fiveruns/json/version.rb", "lib/fiveruns/json.rb", "test/collector_communication_test.rb", "test/configuration_test.rb", "test/data_payload.bin.gz", "test/exception_recorder_test.rb", "test/file_store_test.rb", "test/fixtures", "test/fixtures/http_store_test", "test/fixtures/http_store_test/response.json", "test/http_store_test.rb", "test/json_test.rb", "test/metric_test.rb", "test/recipe_test.rb", "test/reliability_test.rb", "test/reporter_test.rb", "test/scm_test.rb", "test/session_test.rb", "test/test_helper.rb", "test/update_test.rb", "recipes/jruby.rb", "recipes/ruby.rb"]
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
    else
    end
  else
  end
end
