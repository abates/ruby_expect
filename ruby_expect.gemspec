Gem::Specification.new do |s|
  s.name        = 'ruby_expect'
  s.version     = '1.1'
  s.date        = '2013-05-21'
  s.summary     = 'This is a simple expect implementation that provides interactive access to IO objects'
  s.description = 'Ruby implementation for send/expect interaction'
  s.authors     = ['Andrew Bates']
  s.email       = 'abates@omeganetserv.com'
  s.files       = `git ls-files lib`.split("\n")
  s.homepage    = 'https://github.com/abates/ruby_expect'
end
