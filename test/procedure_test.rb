
require 'test_helper'
require 'socket'

class ProcedureTest < Test::Unit::TestCase
  test 'dsl' do
    (s1, s2) = UNIXSocket.socketpair
    s2 << "line1\n"
    s2 << "line2\n"
    s2 << "line3\n"

    match1 = false
    match2 = false

    exp = RubyExpect::Expect.new(s1) do
      each do
        expect /line2/ do
          match1 = true
        end
        expect /line3/ do
          match2 = true
        end
      end
    end
    assert match1
    assert match2
  end

  test 'multi dsl' do
    (s1, s2) = UNIXSocket.socketpair
    s2 << "line1\n"
    s2 << "line2\n"
    s2 << "line3\n"
    s2.flush

    match1 = false
    match2 = false
    match3 = false
    match4 = false

    exp = RubyExpect::Expect.new(s1)
    exp.procedure do
      any do
        expect /line2/ do
          match1 = true
        end
        expect /line22/ do
          match2 = true
        end
      end

      any do
        expect /line33/ do
          match3 = true
        end
        expect /line3/ do
          match4 = true
        end
      end
    end

    assert match1
    assert !match2
    assert !match3
    assert match4
  end
end
