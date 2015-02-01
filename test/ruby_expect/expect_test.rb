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

require 'minitest_helper'
require 'socket'
require 'stringio'
require 'tempfile'

#####
#
#
class ExpectTest < MiniTest::Test
  describe 'basic behavior' do
    before do
      (@s1, @s2) = UNIXSocket.socketpair
      @exp = RubyExpect::Expect.new(@s1)
      @s2 << "line1\n"
      @s2 << "line2\n"
      @s2 << "line3\n"
      @s2.flush
    end

    it 'should return when the expected strings have been encountered in the stream' do
      @exp.expect("line2\n").must_equal(0)
    end

    it 'provides access to the data before the expected string' do
      @exp.expect("line2\n")
      @exp.before.must_equal("line1\n")
    end
    
    it 'provides access to the matched string' do
      @exp.expect("line2\n")
      @exp.match.must_equal("line2\n")
    end

    it 'returns the index of the first matching pattern when multiple patterns are given' do
      @exp.expect("line2\n", "line3\n").must_equal(0)
      @exp.expect("line2\n", "line3\n").must_equal(1)
    end

    it 'calls the block given when an expected pattern is matched' do
      proc_called = false
      @exp.expect("line2\n") do
        proc_called = true
      end

      proc_called.must_equal(true)
    end

    it 'returns nil if it times out while expecting a pattern' do
      @exp.timeout = 1
      @exp.expect('foobar').must_equal(nil)
    end

    it 'provides the ability for the user to directly interact with the IO stream' do
      @exp.expect("line3\n")
      (old_stdin, old_stdout) = [$stdin, $stdout]
      (stdio1, stdio2) = UNIXSocket.socketpair
      $stdin = stdio2
      $stdout = stdio2

      Thread.new do
        @exp.interact
      end

      stdio1 << "First Line\n"
      stdio1.flush

      @s2.gets.must_equal "First Line\n"
      @s2 << "First Response\n"
      @s2.flush
      stdio1.gets.must_equal("First Response\n")
      @s2.close

      $stdin = old_stdin
      $stdout = old_stdout
    end
  end

  describe 'sending data' do
    it 'will write data out to the file handle when calling the send method' do
      (s1, s2) = UNIXSocket.socketpair
      exp = RubyExpect::Expect.new(s1)
      exp.send("a line of text")
      line = s2.gets
      line.must_equal("a line of text\n")
    end
  end

  describe 'soft close' do

    it 'will wait for the filehandle to be closed before exiting' do
      socket_file = Dir::Tmpname.make_tmpname('ruby_expect_test_socket', nil)
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
      buffer.must_match(/Exiting$/)
    end

    it 'shouldn\'t interfere with processes after spawned process has closed' do
      exp = RubyExpect::Expect.spawn('sleep 2')
      exp.soft_close.exitstatus.must_equal(0)
      `ls`
    end

    it 'should return the spawned process status after closing' do
      exp = RubyExpect::Expect.spawn('ls foo')
      exp.soft_close.exitstatus.must_equal(1)
    end
  end
end
