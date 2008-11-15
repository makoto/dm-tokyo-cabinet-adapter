Gem::Specification.new do |s|
  s.name = %q{dm-tokyo-cabinet-adapter}
  s.version = "0.0.1"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Makoto Inoue"]
  s.date = %q{2008-11-15}
  s.description = %q{A DataMapper adapter for Tokyo Cabinet}
  s.email = %q{inouemak@googlemail.com}
  s.files = ["lib/tc_adapter.rb", "README", "Rakefile", "dm-tokyo-cabinet-adapter.gemspec", "spec/tc_adapter_spec.rb", "spec/spec_helper.rb"]
  s.homepage = %q{http://github.com/makoto/dm-tokyo-cabinet-adapter}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{A DatMapper adapter for Tokyo Cabinet}
  s.test_files = ["spec/tc_adapter_spec.rb", "spec/spec_helper.rb"]
end


require 'dm-core'
require 'tokyocabinet'
