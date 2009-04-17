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
        link_fanart(@media.path_to(:fanart))
      end
    end
    result
  end

  def link_fanart(dest_filespec)
    ['original', 'mid', 'cover', 'thumb'].each do |size|
      files = Dir.glob("#{dest_filespec}.#{size}.*")
      unless files.blank?
        filespec = files.sort.first
        extension = File.extname(filespec)
        link_filespec = dest_filespec + extension
        unless File.exist?(link_filespec)
          File.link(filespec, link_filespec)
        end
        break
      end
    end
  end

  protected

  def fetch_fanart(imdb_id)
    profile = TmdbProfile.new(imdb_id, TMDB_API_KEY, @media.path_to(:tmdb_xml), AppConfig[:logger])
    indexes = {}
    unless profile.nil? || profile.movie.blank?
      movie = profile.movie
      unless movie['fanarts'].blank?
        fanarts = movie['fanarts']
        fanarts.each do |fanart|
          AppConfig[:logger].debug { "#{fanart.inspect}" }
          src_url = fanart['content']
          unless src_url.blank?
            dest_filespec = FanartController.get_destination_filespec(@media.media_path, fanart, indexes)
            unless File.exist?(dest_filespec)
              AppConfig[:logger].info { "src_url => #{src_url}" }
              AppConfig[:logger].info { "dest_fanart_filespec => #{dest_filespec}" }
              copy_fanart(src_url, dest_filespec)
            end
          end
        end
      end
    end
  end

  def FanartController.get_destination_filespec(media_path, fanart, indexes)
    extension = File.extname(fanart['content'])
    size = fanart['size']
    unless size.blank?
      indexes[size] ||= -1
      indexes[size] += 1
      extension = ".#{size}.#{indexes[size]}#{extension}"
    end
    fanart_filename = DvdProfiler2Xbmc.generate_filespec(media_path, :fanart, :extension => extension)
  end

  # download the fanart
  def copy_fanart(src_url, dest_filespec)
    begin
      data = read_page(src_url)
      File.open(dest_filespec, 'w') do |file|
        file.print(data)
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error fetching fanart.\n  src_url => #{src_url},\n  dest_filespec => #{dest_filespec}\n  #{e.to_s}" }
    end
  end

  # makes reading from cache during specs possible
  def read_page(src_url)
    open(src_url).read
  end

end
