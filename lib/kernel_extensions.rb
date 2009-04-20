require 'module_extensions'

# == Synopsis
# Various extensions to the Kernel class
# Note, uses the Module.my_extension method to only add the method if
# it doesn't already exist.
module Kernel
  my_extension("timer") do
    # == Synopsis
    # a simple elapse time for the give block
    # == Usage
    # elapse_seconds = timer {...}
    def timer
      start_time = Time.now
      yield
      Time.now - start_time
    end
  end
end

