######################################################################
# my extensions to Module. (taken from rake, named changed to not clash
# when rake is used for this rails project.
#
class Module
  # Check for an existing method in the current class before extending.  IF
  # the method already exists, then a warning is printed and the extension is
  # not added.  Otherwise the block is yielded and any definitions in the
  # block will take effect.
  #
  # Usage:
  #
  #   class String
  #     rake_extension("xyz") do
  #       def xyz
  #         ...
  #       end
  #     end
  #   end
  #
  def my_extension(method)
    unless instance_methods.include?(method.to_s) || instance_methods.include?(method.to_sym)
      yield
    end
  end
end # module Module

######################################################################
# User defined methods to be added to String.
#
class String
  my_extension("ext") do
    # Replace the file extension with +newext+.  If there is no extenson on
    # the string, append the new extension to the end.  If the new extension
    # is not given, or is the empty string, remove any existing extension.
    #
    # +ext+ is a user added method for the String class.
    def ext(newext='')
      return self.dup if ['.', '..'].include? self
      if newext != ''
        newext = (newext =~ /^\./) ? newext : ("." + newext)
      end
      dup.sub!(%r(([^/\\])\.[^./\\]*$)) { $1 + newext } || self + newext
    end
  end
end # class String

# == Synopsis
# add a blank? method to all Objects
class Object
  my_extension("blank?") do
    # return asserted if object is nil or empty
    # TODO: not the safest coding, probably should dup before stripping.  Maybe should also compact
    def blank?
      result = nil?
      unless result
        if respond_to? 'empty?'
          if respond_to? 'strip'
            result = strip.empty?
          else
            result = empty?
          end
        end
      end
      result
    end
  end
end

# == Synopsis
# add an elapse_time_s method to Numeric
class Numeric
  my_extension("elapsed_time_s") do
    # return String formated as "HH:MM:SS"
    def elapsed_time_s
      seconds = self
      hours = minutes = 0
      hours = seconds.div 3600
      seconds = seconds - (hours * 3600)
      minutes = seconds.div 60
      seconds = seconds - (minutes * 60)
      sprintf("%2.2d:%2.2d:%2.2d", hours, minutes, seconds)
    end
  end
end

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

