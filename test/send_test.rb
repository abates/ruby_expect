
require 'test_helper'
require 'socket'

class SendTest < Test::Unit::TestCase
  test 'Sending data goes out the socket' do
    (s1, s2) = UNIXSocket.socketpair
    exp = RubyExpect::Expect.new(s1)
    exp.send("a line of text")
    line = s2.gets
    assert_equal "a line of text\n", line
  end
end
