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

require 'spec_helper'
require 'socket'

describe RubyExpect::Procedure do
  before :each do
    (s1, s2) = UNIXSocket.socketpair
    s2 << "line1\n"
    s2 << "line2\n"
    s2 << "line3\n"
    s2.flush

    match1 = false
    match2 = false

    @exp = RubyExpect::Expect.new(s1)
  end

  it 'provides a way to expect a series of patterns' do
    match1 = false
    match2 = false
    @exp.procedure do
      each do
        expect /line2/ do
          match1 = true
        end

        expect /line3/ do
          match2 = true
        end
      end
    end
    expect(match1).to be(true)
    expect(match2).to be(true)
  end

  it 'provides a way to match any pattern in a set of patterns' do
    match1 = false
    match2 = false
    match3 = false
    match4 = false

    @exp.procedure do
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

    expect(match1).to be(true)
    expect(match2).to be(false)
    expect(match3).to be(false)
    expect(match4).to be(true)
  end
end
