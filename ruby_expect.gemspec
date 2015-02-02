# -*- encoding: utf-8 -*-
# stub: ruby_expect 1.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby_expect"
  s.version = "1.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Andrew Bates"]
  s.date = "2014-10-27"
  s.description = "Ruby implementation for send/expect interaction"
  s.email = "abates@omeganetserv.com"
  s.files = ["lib/ruby_expect.rb", "lib/ruby_expect/expect.rb", "lib/ruby_expect/procedure.rb"]
  s.homepage = "https://github.com/abates/ruby_expect"
  s.rubygems_version = "2.2.2"
  s.summary = "This is a simple expect implementation that provides interactive access to IO objects"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, ["~> 5.3"])
    else
      s.add_dependency(%q<minitest>, ["~> 5.3"])
    end
  else
    s.add_dependency(%q<minitest>, ["~> 5.3"])
  end
end
