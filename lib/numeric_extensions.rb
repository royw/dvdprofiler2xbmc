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

