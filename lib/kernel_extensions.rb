# # == Synopsis
# # add a mkdirs method to the File class
# class File
#   ##
#   # make directories including any missing in the path
#   #
#   # @param [String] dirspec the path to make sure exists
#   def File.mkdirs(dirspec)
#     unless File.exists?(dirspec)
#       mkdirs(File.dirname(dirspec))
#       Dir.mkdir(dirspec)
#     end
#   end
# end

# == Synopsis
# add a timer method to the Kernel
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

