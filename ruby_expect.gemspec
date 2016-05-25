# -*- encoding: utf-8 -*-
# stub: ruby_expect 1.7.4 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby_expect"
  s.version = "1.7.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Andrew Bates"]
  s.bindir = "exe"
  s.date = "2016-01-06"
  s.description = "Ruby implementation for send/expect interaction"
  s.email = ["abates@omeganetserv.com"]
  s.files = [".gitignore", ".rspec", ".travis.yml", "Gemfile", "LICENSE", "NOTICE", "README.md", "Rakefile", "bin/console", "bin/setup", "lib/ruby_expect.rb", "lib/ruby_expect/errors.rb", "lib/ruby_expect/expect.rb", "lib/ruby_expect/procedure.rb", "lib/ruby_expect/version.rb", "ruby_expect.gemspec"]
  s.homepage = "https://github.com/abates/ruby_expect"
  s.rubygems_version = "2.4.8"
  s.summary = "This is a simple expect implementation that provides interactive access to IO objects"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.10"])
      s.add_development_dependency(%q<rake>, ["~> 11.0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.10"])
      s.add_dependency(%q<rake>, ["~> 11.0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.10"])
    s.add_dependency(%q<rake>, ["~> 11.0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
  end
end
