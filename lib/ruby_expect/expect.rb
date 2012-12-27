require 'thread'

module RubyExpect
  class Expect
    attr_reader :before, :match, :buffer

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
      patterns = {}
      if (match_patterns.last.is_a?(Hash))
        hash = match_patterns.pop
        match_patterns.push(*hash.to_a.flatten)
      end

      last_pattern = ''
      if (match_patterns.size == 1)
        patterns[pattern_escape(match_patterns[0])] = { :process => 1, :index => 0 }
      else
        index = 0
        match_patterns.each do |pattern|
          if (pattern.is_a?(Proc))
            patterns[last_pattern][:proc] = pattern
          else
            pattern = pattern_escape(pattern)
            patterns[pattern] = {:proc => nil, :index => index }
            index += 1
            last_pattern = pattern
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
        @buffer_sem.synchronize do
          patterns.each do |pattern, p|
            if (match = pattern.match(@buffer))
              @before = @buffer.slice!(0...match.begin(0))
              @match = @buffer.slice!(0...match.to_s.length)
              if (p[:proc].is_a?(Proc))
                p[:proc].call
              end
              return p[:index]
            end
          end
          @buffer_cv.wait(@buffer_sem)
        end
      end
      return nil
    end
  end
end

