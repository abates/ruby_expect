module RubyExpect
  class Pattern
    attr_reader :pattern, :block
    def initialize pattern, &block
      @pattern = pattern
      @block = block
    end
  end

  class Match
    def initialize exp_object, &block
      @exp = exp_object
      @patterns = []
      instance_eval(&block) unless block.nil?
    end

    def expect pattern, &block
      @patterns.push(Pattern.new(pattern, &block))
    end
  end

  class AnyMatch < Match
    def run
      retval = @exp.expect(*@patterns.collect {|p| p.pattern})
      unless (retval.nil?)
        @exp.instance_eval(&@patterns[retval].block) unless (@patterns[retval].block.nil?)
      end
      return retval
    end
  end
    
  class EachMatch < Match
    def run
      @patterns.each_index do |i|
        retval = @exp.expect(@patterns[i].pattern, &@patterns[i].block)
        return nil if (retval.nil?)
      end
      return nil
    end
  end

  class Procedure
    def initialize exp_object, &block
      raise "First argument must be a RubyExpect::Expect object" unless (exp_object.is_a?(RubyExpect::Expect))
      @exp = exp_object
      @steps = []
      instance_eval(&block) unless block.nil? 
    end

    def run
      @steps.each_index do |i|
        @steps[i].run
      end
    end

    def any &block
      @steps.push(RubyExpect::AnyMatch.new(@exp, &block))
    end

    def each &block
      @steps.push(RubyExpect::EachMatch.new(@exp, &block))
    end
  end
end
