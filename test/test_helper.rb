
#$:.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'test/unit'
require 'ruby_expect'

class Test::Unit::TestCase
  # Thanks rails!
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        raise "No implementation provided for #{name}"
      end
    end
  end
end
