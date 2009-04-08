# == Synopsis
# Media encapsulates information about a single media file
#
# Usage:
#  controller = FanartController.new(media)
#  controller.update
# or
#  FanartController.update(media)
class FanartController
  attr_reader :media_path, :image_files, :year, :media_subdirs, :title, :title_with_year

  def self.update(media)
    FanartController.new(media).update
  end

  def initialize(media)
    @media = media
  end

  # update the meta-data and thumbnails
  def update
    result = true
    unless @media.imdb_id.blank?
      if @media.fanart_files.empty?
        fetch_fanart(@media.imdb_id)
      end
    end
    result
  end

  protected

  DISC_NUMBER_REGEX = /\.(cd|part|disk|disc)\d+/i

  def fetch_fanart(imdb_id)
    # TODO the fanart hash should be retrieved from the nfo_controller
    profile = TmdbProfile.new(imdb_id, @media.path_to(:tmdb_xml_extension))
    unless profile.nil? || profile.movie.blank?
      movie = profile.movie
      unless movie['fanarts'].blank?
        fanart = movie['fanarts'].first
        AppConfig[:logger].debug { "#{fanart.inspect}" }
        src_url = fanart['content']
        unless src_url.blank?
          fanart_filename = File.basename(@media.media_path, ".*").gsub(DISC_NUMBER_REGEX, '')
          fanart_filename += AppConfig[:fanart_extension]
          fanart_filename += File.extname(src_url)
          dest_filespec = File.join(File.dirname(@media.media_path), fanart_filename)
          unless File.exist?(dest_filespec)
            AppConfig[:logger].info { "src_url => #{src_url}" }
            AppConfig[:logger].info { "dest_fanart_filespec => #{dest_filespec}" }
            copy_fanart(src_url, dest_filespec)
          end
        end
      end
    end
  end

  def copy_fanart(src_url, dest_filespec)
    begin
      data = open(src_url).read
      File.open(dest_filespec, 'w') do |file|
        file.print(data)
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error fetching fanart.\n  src_url => #{src_url},\n  dest_filespec => #{dest_filespec}\n  #{e.to_s}" }
    end
  end

end
