require 'module_extensions'

# == Synopsis
# Various extensions to the File class
# Note, uses the Module.my_extension method to only add the method if
# it doesn't already exist.
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
