module RubyExpect
  #####
  # Raised when attempt is made to interact with a closed filehandle 
  #
  class ClosedError < StandardError
  end
end
