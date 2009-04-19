# == Synopsis
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

  # == Synopsis
  # filespec => String pathspec to the .nfo file
  def initialize(filespec)
    @nfo_filespec = filespec
    @movie = nil
    @original_movie = nil
    load
  end

  # == Synopsis
  # return the movie hash that contains the media meta data
  def movie
    @movie ||= Hash.new
    @movie
  end

  # == Synopsis
  # set the movie hash
  def movie=(other)
    @movie = other
  end

  # == Synopsis
  # convert the @movie hash into xml and return the xml as a String
  def to_xml
    xml = ''
    begin
      unless @movie.blank?
        data = filter(@movie.dup)
        xml = XmlSimple.xml_out(data, 'NoAttr' => true, 'RootName' => 'movie')
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error creating nfo file - " + e.to_s}
      raise e
    end
    xml
  end

  # == Synopsis
  # save the profile to the .nfo file, but only if it has changed
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

  FILTER_HTML = /<[^>]*>/

  # == Synopsis
  # filter the given movie hash first collapsing (removing from Array)
  # the plot, tagline, and overview values by removing, then removing
  # any HTML tags such as <b></b>, <i></i>,...
  def filter(data)
    data.delete_if { |key, value| value.nil? }
    %w(plot tagline overview).each do |key|
      if data[key].respond_to?('first')
        data[key] = data[key].first
      end
      data[key] = data[key].gsub(FILTER_HTML, '') unless data[key].blank?
    end
    data
  end

  # == Synopsis
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

  # == Synopsis
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