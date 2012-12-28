
require 'test_helper'
require 'socket'

class ExpectTest < Test::Unit::TestCase
  test 'expected data causes expect method to return' do
    (s1, s2) = UNIXSocket.socketpair
    exp = RubyExpect::Expect.new(s1)
    s2 << "line1\n"
    s2 << "line2\n"
    s2 << "line3\n"
    retval = exp.expect("line2\n")
    assert retval
  end

  test 'string before expected data does not include expected data' do
    (s1, s2) = UNIXSocket.socketpair
    exp = RubyExpect::Expect.new(s1)
    s2 << "line1\n"
    s2 << "line2\n"
    s2 << "line3\n"
    retval = exp.expect("line2\n")
    assert_equal "line1\n", exp.before
  end

  test 'match string is equal to expected data' do
    (s1, s2) = UNIXSocket.socketpair
    exp = RubyExpect::Expect.new(s1)
    s2 << "line1\n"
    s2 << "line2\n"
    s2 << "line3\n"
    retval = exp.expect("line2\n")
    assert_equal "line2\n", exp.match
  end

  test 'multiple patterns return first match' do
    (s1, s2) = UNIXSocket.socketpair
    exp = RubyExpect::Expect.new(s1)
    s2 << "line1\n"
    s2 << "line2\n"
    s2 << "line3\n"

    retval = exp.expect("line2\n", "line3\n")
    assert_equal 0, retval
    retval = exp.expect("line2\n", "line3\n")
    assert_equal 1, retval
  end

  test 'callback' do
    (s1, s2) = UNIXSocket.socketpair
    exp = RubyExpect::Expect.new(s1)
    s2 << "line1\n"
    s2 << "line2\n"
    s2 << "line3\n"
    proc_called = false
    retval = exp.expect(
      "line2\n", Proc.new do
        proc_called = true
      end

    )

    assert proc_called
  end

  test 'multiple callbacks' do
    (s1, s2) = UNIXSocket.socketpair
    exp = RubyExpect::Expect.new(s1)
    s2 << "line1\n"
    s2 << "line2\n"
    s2 << "line3\n"

    match1 = false
    match2 = false
    retval = exp.expect(
      "line2\n", Proc.new { match1 = true }, 
      "line3\n", Proc.new { match2 = true }
    )
    assert_equal 0, retval
    retval = exp.expect(
      "line2\n", Proc.new { match1 = true }, 
      "line3\n", Proc.new { match2 = true }
    )
    assert_equal 1, retval

    assert match1
    assert match2
  end
end
