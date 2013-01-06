#####
# = LICENSE
#
# Copyright 2012 Andrew Bates Licensed under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#

require 'test_helper'
require 'socket'

#####
#
#
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
    retval = exp.expect("line2\n") do
      proc_called = true
    end

    assert proc_called
  end
end
