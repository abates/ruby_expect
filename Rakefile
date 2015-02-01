require 'rake/testtask'
require 'rubygems/tasks'


Gem::Tasks.new

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/ruby_expect/*_test.rb']
end

