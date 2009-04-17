# == Synopsis
# add a blank? method to all Objects
class Object
  my_extension("blank?") do
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
