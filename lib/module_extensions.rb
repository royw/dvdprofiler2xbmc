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

