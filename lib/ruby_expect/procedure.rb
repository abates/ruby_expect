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

#####
#
#
module RubyExpect
  #####
  # A pattern is a simple container to hold a string/regexp pattern and proc to
  # be called upon match.  This is an internal container used by the Procedure
  # class
  #
  class Pattern
    attr_reader :pattern, :block
    #####
    # +pattern+::
    #   String or Regexp objects to match on
    #
    # +block+::
    #   The block/proc to be called if a match occurs
    #
    def initialize pattern, &block
      @pattern = pattern
      @block = block
    end
  end

  #####
  # Super class for common methods for AnyMatch and EachMatch
  #
  class Match
    #####
    # +exp_object+::
    #   The expect object used for interaction
    #
    # +block+::
    #   The block will be called in the context of the initialized match object
    #
    def initialize exp_object, &block
      @exp = exp_object
      @patterns = []
      instance_eval(&block) unless block.nil?
    end

    #####
    # Add a pattern to be expected by the process
    #
    # +pattern+::
    #   String or Regexp to match on
    #
    # +block+::
    #   Block to be called upon a match
    #
    def expect pattern, &block
      @patterns.push(Pattern.new(pattern, &block))
    end
  end

  #####
  # Expect any one of the specified patterns and call the matching pattern's
  # block
  #
  class AnyMatch < Match
    #####
    # Procedure input data for the set of expected patterns
    #
    def run
      retval = @exp.expect(*@patterns.collect {|p| p.pattern})
      unless (retval.nil?)
        @exp.instance_eval(&@patterns[retval].block) unless (@patterns[retval].block.nil?)
      end
      return retval
    end
  end
    
  #####
  # Expect each of a set of patterns
  #
  class EachMatch < Match
    #####
    # Procedure input data for the set of expected patterns
    #
    def run
      @patterns.each_index do |i|
        retval = @exp.expect(@patterns[i].pattern, &@patterns[i].block)
        return nil if (retval.nil?)
      end
      return nil
    end
  end

  #####
  # A proedure is a set of patterns to match and blocks to be called upon
  # matching patterns.  This is useful for building blocks of expected sequences
  # of input data.  An example of this could be logging into a system using SSH
  #
  # == Example
  #
  #  retval = 0
  #  while (retval != 2)
  #    retval = any do
  #      expect /Are you sure you want to continue connecting \(yes\/no\)\?/ do
  #        send 'yes'
  #      end
  #
  #      expect /password:\s*$/ do
  #        send password
  #      end
  #
  #      expect /\$\s*$/ do
  #        send 'uptime'
  #      end
  #    end
  #  end
  #
  #  # Expect each of the following
  #  each do
  #    expect /load\s+average:\s+\d+\.\d+,\s+\d+\.\d+,\s+\d+\.\d+/ do # expect the output of uptime
  #      puts last_match.to_s
  #    end
  #
  #    expect /\$\s+$/ do # shell prompt
  #      send 'exit'
  #    end
  #  end
  #
  class Procedure
    #####
    # +exp_object+::
    #
    # +block+::
    #
    def initialize exp_object, &block
      raise "First argument must be a RubyExpect::Expect object" unless (exp_object.is_a?(RubyExpect::Expect))
      @exp = exp_object
      @steps = []
      instance_eval(&block) unless block.nil? 
    end

    #####
    # Add an 'any' block to the Procedure.  The block will be evaluated using a
    # new AnyMatch instance
    #
    # +block+::
    #
    #   The block the specifies the patterns to expect
    #
    def any &block
      RubyExpect::AnyMatch.new(@exp, &block).run
    end

    #####
    # Add an 'each' block to the Procedure.  The block will be evaluated using a
    # new EachMatch instance
    #
    # +block+::
    #   The block that specifies the patterns to expect
    #
    def each &block
      RubyExpect::EachMatch.new(@exp, &block).run
    end
  end
end
