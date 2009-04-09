# This is the model for the XBMC's Info profile which is used
# to manage a .nfo file
#
# Usage:
#
# profile = XbmcInfo.new(media.path_to(:nfo))
#
# profile.movie['key'] = 'some value'
# puts profile.movie['key']
# puts profile.to_xml
# puts profile.save
#
class XbmcInfo

  FILTER_HTML = /<[^>]*>/

  def initialize(filespec)
    @nfo_filespec = filespec
    @movie = nil
    @original_movie = nil
    load
  end

  def movie
    @movie ||= Hash.new
    @movie
  end

  def movie=(other)
    @movie = other
  end

  # convert the @movie hash into xml and return the xml as a String
  def to_xml
    xml = ''
    begin
      unless @movie.blank?
        data = @movie.dup
        data.delete_if { |key, value| value.nil? }
        %w(plot tagline overview).each do |key|
          if data[key].respond_to?('first')
            data[key] = data[key].first
          end
          data[key] = data[key].gsub(FILTER_HTML, '') unless data[key].blank?
        end
        xml = XmlSimple.xml_out(data, 'NoAttr' => true, 'RootName' => 'movie')
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error creating nfo file - " + e.to_s}
      raise e
    end
    xml
  end

  def save
    begin
      if dirty?
        xml = self.to_xml
        unless xml.blank?
          AppConfig[:logger].info { "updated #{@nfo_filespec}"}
          DvdProfiler2Xbmc.save_to_file(@nfo_filespec, xml)
        end
      end
    rescue Exception => e
      AppConfig[:logger].error "Unable to save xbmc info to #{@nfo_filespec} - #{e.to_s}"
    end
  end

  protected

  # load the .nfo file into the @movie hash
  def load
    begin
      if File.exist?(@nfo_filespec) && (File.size(@nfo_filespec) > 1)
        File.open(@nfo_filespec) do |file|
          @movie = XmlSimple.xml_in(file)
          @original_movie = @movie.dup
        end
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error loading \"#{@nfo_filespec}\" - " + e.to_s + "\n" + e.backtrace.join("\n") }
      raise e
    end
  end

#   def save_to_file(filespec, data)
#     new_filespec = filespec + AppConfig[:new_extension]
#     File.open(new_filespec, "w") do |file|
#       file.puts(data)
#     end
#     backup_filespec = filespec + AppConfig[:extension][:backup]
#     File.delete(backup_filespec) if File.exist?(backup_filespec)
#     File.rename(filespec, backup_filespec) if File.exist?(filespec)
#     File.rename(new_filespec, filespec)
#     File.delete(new_filespec) if File.exist?(new_filespec)
#   end

  # has any of the data changed?
  def dirty?
    result = false
    if @original_movie.nil?
      result = true
    else
      @movie.each do |key, value|
        if @original_movie[key].nil?
          result = true
          break
        end
        if @movie[key].to_s != @original_movie[key].to_s
          result = true
          break
        end
      end
      unless result
        diff_keys = @movie.keys.sort - @original_movie.keys.sort
        unless diff_keys.empty?
          result = true
        end
      end
    end
    result
  end

end