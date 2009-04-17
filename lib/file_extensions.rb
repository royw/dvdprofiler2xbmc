# == Synopsis
# add a mkdirs method to the File class
class File
  class << self
    my_extension("mkdirs") do
      ##
      # make directories including any missing in the path
      #
      # @param [String] dirspec the path to make sure exists
      def File.mkdirs(dirspec)
        unless File.exists?(dirspec)
          mkdirs(File.dirname(dirspec))
          Dir.mkdir(dirspec)
        end
      end
    end
  end
end
