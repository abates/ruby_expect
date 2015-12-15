# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_expect/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby_expect"
  spec.version       = RubyExpect::VERSION
  spec.authors       = ["Andrew Bates"]
  spec.email         = ["abates@omeganetserv.com"]

  spec.summary = %q{This is a simple expect implementation that provides interactive access to IO objects}
  spec.description = %q{Ruby implementation for send/expect interaction}
  spec.homepage = "https://github.com/abates/ruby_expect"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
end
