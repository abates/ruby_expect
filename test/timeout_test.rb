
require 'test_helper'
require 'socket'

class TimeoutTest < Test::Unit::TestCase
  test 'no match after timeout returns nil' do
    (s1, s2) = UNIXSocket.socketpair
    exp = RubyExpect::Expect.new(s1)
    exp.timeout = 1
    retval = exp.expect('foobar')
    assert_nil retval
  end
end
