require 'thread'

module RubyExpect
  class Expect
    attr_reader :before, :match, :last_match, :buffer

    def initialize io, options = {}
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
      read_loop
    end

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

    def send command
      @io.write("#{command}\n")
    end

    def pattern_escape pattern
      if (pattern.is_a?(String))
        pattern = Regexp.new(Regexp.escape(pattern))
      elsif (! pattern.is_a?(Regexp))
        raise "Don't know how to match on a #{pattern.class}"
      end
      pattern
    end

    def expect *match_patterns, &block
      patterns = []

      i = 0
      if (match_patterns.size == 1)
        patterns[0] = { :pattern => pattern_escape(match_patterns[0]), :process => nil, :index => 0 }
      else
        match_patterns.each do |pattern|
          if (pattern.is_a?(Proc))
            patterns.last[:proc] = pattern
          else
            pattern = pattern_escape(pattern)
            patterns[i] = {:pattern => pattern, :proc => nil, :index => i }
            i += 1
          end
        end
      end

      @end_time = 0
      if (@timeout != 0)
        @end_time = Time.now + @timeout
      end

      @before = ''
      while (@end_time == 0 || Time.now < @end_time)
        return nil if (@io.closed?)
        @last_match = nil
        @buffer_sem.synchronize do
          patterns.each_index do |i|
            if (match = patterns[i][:pattern].match(@buffer))
              @last_match = patterns[i]
              @before = @buffer.slice!(0...match.begin(0))
              @match = @buffer.slice!(0...match.to_s.length)
              break
            end
          end
          @buffer_cv.wait(@buffer_sem) if (@last_match.nil?)
        end
        unless (@last_match.nil?)
          if (@last_match[:proc].is_a?(Proc))
            @last_match[:proc].call
          end
          return @last_match[:index]
        end
      end
      return nil
    end
  end
end

