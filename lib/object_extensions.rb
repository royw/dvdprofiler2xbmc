require 'module_extensions'

# == Synopsis
# Various extensions to the Object class
# Note, uses the Module.my_extension method to only add the method if
# it doesn't already exist.
class Object
  my_extension("blank?") do
    # == Synopsis
    # return asserted if object is nil or empty
    def blank?
      result = nil?
      unless result
        if respond_to? 'empty?'
          if respond_to? 'strip'
            result = strip.empty?
          else
            if respond_to? 'compact'
              result = compact.empty?
            else
              result = empty?
            end
          end
        end
      end
      result
    end
  end
end
