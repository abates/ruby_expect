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
require 'thread'
require 'ruby_expect/procedure'

#####
#
#
module RubyExpect
  #####
  # This is the main class used to interact with IO objects An Expect object can
  # be used to send and receive data on any read/write IO object.
  #
  class Expect
    # Any data that was in the accumulator buffer before match in the last expect call
    # if the last call to expect resulted in a timeout, then before is an empty string
    attr_reader :before

    # The exact string that matched in the last expect call
    attr_reader :match

    # The MatchData object from the last expect call or nil upon a timeout
    attr_reader :last_match

    # The accumulator buffer populated by read_loop.  Only access this if you really
    # know what you are doing!
    attr_reader :buffer

    #####
    # Create a new Expect object for the given IO object
    #
    # +io+::
    #   The IO object with which to interact
    #
    # +options+::
    #   Currently the only option supported is :debug If :debug is true then the
    #   interaction will be displayed on STDOUT
    #
    # +block+::
    #   An optional block called upon initialization.  See procedure
    #
    def initialize io, options = {}, &block
      if (io.is_a?(IO))
        @io = io
      else
        raise "Argument to initialize must be an IO object"
      end

      @buffer_sem = Mutex.new
      @buffer_cv = ConditionVariable.new
      @debug = options[:debug] || false
      @buffer = ''
      @before = ''
      @match = ''
      @timeout = 0

      read_loop # start the read thread

      unless (block.nil?)
        procedure(&block)
      end
    end

    #####
    # Perform a series of 'expects' using the DSL defined in Procedure
    #
    # +block+::
    #   The block will be called in the context of a new Procedure object
    #
    # == Example
    #
    #    exp = Expect.new(io)
    #    exp.procedure do
    #     each do
    #       expect /first expected line/ do
    #         send "some text to send"
    #       end
    #
    #       expect /second expected line/ do
    #         send "some more text to send"
    #       end
    #     end
    #    end
    #
    def procedure &block
      RubyExpect::Procedure.new(self, &block).run
    end

    #####
    # Set the time to wait for an expected pattern
    #
    # +timeout+::
    #   number of seconds to wait before giving up.  A value of zero means wait
    #   forever
    #
    def timeout= timeout
      unless (timeout.is_a?(Integer))
        raise "Timeout must be an integer"
      end
      unless (timeout >= 0)
        raise "Timeout must be greater than or equal to zero"
      end

      @timeout = timeout
      @end_time = 0
    end

    #####
    # Convenience method that will send a string followed by a newline to the
    # write handle of the IO object
    #
    # +command+::
    #   String to send down the pipe
    #
    def send command
      @io.write("#{command}\n")
    end

    #####
    # Wait until either the timeout occurs or one of the given patterns is seen
    # in the input.  Upon a match, the property before is assigned all input in
    # the accumulator before the match, the matched string itself is assigned to
    # the match property and an optional block is called
    #
    # The method will return the index of the matched pattern or nil if no match
    # has occurred during the timeout period
    #
    # +patterns+::
    #   list of patterns to look for.  These can be either literal strings or
    #   Regexp objects
    #
    # +block+::
    #   An optional block to be called if one of the patterns matches
    #
    # == Example
    #
    #    exp = Expect.new(io)
    #    exp.expect('Password:') do
    #      send("12345")
    #    end 
    #
    def expect *patterns, &block
      patterns = pattern_escape(*patterns)

      @end_time = 0
      if (@timeout != 0)
        @end_time = Time.now + @timeout
      end

      @before = ''
      matched_index = nil
      while (@end_time == 0 || Time.now < @end_time)
        return nil if (@io.closed?)
        @last_match = nil
        @buffer_sem.synchronize do
          patterns.each_index do |i|
            if (match = patterns[i].match(@buffer))
              @last_match = match
              @before = @buffer.slice!(0...match.begin(0))
              @match = @buffer.slice!(0...match.to_s.length)
              matched_index = i
              break
            end
          end
          @buffer_cv.wait(@buffer_sem) if (@last_match.nil?)
        end
        unless (@last_match.nil?)
          unless (block.nil?)
            instance_eval(&block)
          end
          return matched_index
        end
      end
      return nil
    end

    private
      #####
      # This method will convert any strings in the argument list to regular
      # expressions that search for the literal string
      #
      # +patterns+::
      #   List of patterns to escape
      #
      def pattern_escape *patterns
        escaped_patterns = []
        patterns.each do |pattern|
          if (pattern.is_a?(String))
            pattern = Regexp.new(Regexp.escape(pattern))
          elsif (! pattern.is_a?(Regexp))
            raise "Don't know how to match on a #{pattern.class}"
          end
          escaped_patterns.push(pattern)
        end
        escaped_patterns
      end

      #####
      # The read loop is an internal method that constantly waits for input to
      # arrive on the IO object.  When input arrives it is appended to an
      # internal buffer for use by the expect method
      #
      def read_loop
        Thread.abort_on_exception = true
        Thread.new do
          while (true)
            begin
              ready = IO.select([@io], nil, nil, 1)
              if (ready.nil? || ready.size == 0)
                @buffer_cv.signal()
              else
                input = @io.readpartial(4096)
                @buffer_sem.synchronize do
                  @buffer << input
                  @buffer_cv.signal()
                end
                if (@debug)
                  STDERR.print input
                  STDERR.flush
                end
              end
            rescue EOFError => e
            rescue Exception => e
              unless (e.to_s == 'stream closed')
                STDERR.print "#{e}\n"
                STDERR.print "\t#{e.backtrace.join("\n\t")}\n"
                STDERR.flush
              end
              break
            end
          end
        end
      end
  end
end

