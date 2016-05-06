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
require 'stringio'
require 'tempfile'

describe RubyExpect::Expect do
  before :each do
    (@s1, @s2) = UNIXSocket.socketpair
    @s2 << "line1\n"
    @s2 << "line2\n"
    @s2 << "line3\n"
    @s2.flush
  end

  it 'should return when the expected strings have been encountered in the stream' do
    exp = RubyExpect::Expect.new(@s1)
    expect(exp.expect("line2\n")).to eq(0)
  end

  it 'provides access to the data before the expected string' do
    exp = RubyExpect::Expect.new(@s1)
    exp.expect("line2\n")
    expect(exp.before).to eq("line1\n")
  end
  
  it 'provides access to the matched string' do
    exp = RubyExpect::Expect.new(@s1)
    exp.expect("line2\n")
    expect(exp.match).to eq("line2\n")
  end

  it 'returns the index of the first matching pattern when multiple patterns are given' do
    exp = RubyExpect::Expect.new(@s1)
    expect(exp.expect("line2\n", "line3\n")).to eq(0)
    expect(exp.expect("line2\n", "line3\n")).to eq(1)
  end

  it 'calls the block given when an expected pattern is matched' do
    exp = RubyExpect::Expect.new(@s1)
    proc_called = false
    exp.expect("line2\n") do
      proc_called = true
    end

    expect(proc_called).to be(true)
  end

  it 'returns nil if it times out while expecting a pattern' do
    exp = RubyExpect::Expect.new(@s1)
    exp.timeout = 1
    expect(exp.expect('foobar')).to eq(nil)
  end

  it 'provides the ability for the user to directly interact with the IO stream' do
    exp = RubyExpect::Expect.new(@s1)
    exp.expect("line3\n")
    (old_stdin, old_stdout) = [$stdin, $stdout]
    (stdio1, stdio2) = UNIXSocket.socketpair
    $stdin = stdio2
    $stdout = stdio2

    Thread.new do
      exp.interact
    end

    stdio1 << "First Line\n"
    stdio1.flush

    expect(@s2.gets).to eq("First Line\n")
    @s2 << "First Response\n"
    @s2.flush
    expect(stdio1.gets).to eq("First Response\n")
    @s2.close

    $stdin = old_stdin
    $stdout = old_stdout
  end

  it 'will write data out to the file handle when calling the send method' do
    exp = RubyExpect::Expect.new(@s1)
    (s1, s2) = UNIXSocket.socketpair
    exp = RubyExpect::Expect.new(s1)
    exp.send("a line of text")
    line = s2.gets
    expect(line).to eq("a line of text\n")  
  end

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
    expect(buffer).to match(/Exiting$/)
  end

  it 'shouldn\'t interfere with processes after spawned process has closed' do
    exp = RubyExpect::Expect.spawn('sleep 2')
    expect(exp.soft_close.exitstatus).to eq(0)
    `ls`
  end

  it 'should return the spawned process status after closing' do
    exp = RubyExpect::Expect.spawn('ls foo')
    expect(exp.soft_close.exitstatus).to_not eq(0)
  end

  it 'should raise an error if expect is called after the read handle is closed' do
    exp = RubyExpect::Expect.new(@s1)
    @s1.close
    expect {
      exp.expect("line2\n")
    }.to raise_error(RubyExpect::ClosedError)
  end
  
  it 'should use an optional logger to receive data sent and received on the IO filehandle' do
    logger = double
    allow(logger).to receive(:debug?).and_return(true)
    allow(logger).to receive(:info?).and_return(true)
    expect(logger).to receive(:debug).with("Expecting [\"line1\"]")
    expect(logger).to receive(:info).with("line1\nline2\nline3\n")
    expect(logger).to receive(:debug).with("Matched line1")
    exp = RubyExpect::Expect.new(@s1, logger: logger)
    exp.expect("line1")
  end
end

