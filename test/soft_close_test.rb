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
class SoftCloseTest < Test::Unit::TestCase
  def start_server
    socket_file = 'ruby_expect_soft_close_test.sock'
    File.unlink(socket_file) if (File.exists?(socket_file))

    server = UNIXServer.new(socket_file)
    fork do
      socket = server.accept
      line = ''
      begin
        while (line = socket.gets)
          line.strip!
          case line
          when 'list'
            socket.print "item1\nitem2\nitem3\nitem4\n"
          when /set (\w+)=(\w+)/
            socket.print "New value for #{$1} is #{$2}\n"
          when 'exit'
            sleep 2
            socket.print "Exiting\n"
            break
          end
        end
      ensure
        socket.close
      end
    end
    return socket_file
  end

  test 'exiting from remote process will cause process to wait until remote end is closed' do
    socket_file = start_server
    exp = RubyExpect::Expect.connect(socket_file)

    exp.send("list")
    exp.procedure do
      each do
        expect /item2$/ do
          send "set item2=newValue"
        end
        expect /item2 is newValue$/ do
          send 'exit'
        end
      end
    end
    exp.soft_close
    buffer = exp.buffer
    File.unlink(socket_file) if (File.exists?(socket_file))
    assert buffer =~ /Exiting$/, "Did not see end of buffer"
  end

  test 'pty - exited behavior with spawned process' do
    exp = RubyExpect::Expect.spawn('sleep 2')
    exp.soft_close
    assert_nothing_raised do
      `ls`
    end
  end
end
