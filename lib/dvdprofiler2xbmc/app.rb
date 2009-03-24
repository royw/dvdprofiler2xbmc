# == Synopsis
# Transfer media meta data from DvdProfiler to the format that XBMC needs it (.tbn and .nfo files)
#
# usage:
#  app = DvdProfiler2Xbmc.new
#  app.execute
#  app.report.each {|line| puts line}
class DvdProfiler2Xbmc
  include Singleton

  @interrupted = false

  # A trap("INT") in the Runner calls this to indicate that a ^C has been detected.
  # Note, once set, it is never cleared
  def self.interrupt
    AppConfig[:logger].error { "control-C detected, finishing current task" }
    @interrupted = true
  end

  # Long loops should poll this method to see if they should abort
  # Returns:: true if the application has trapped an "INT", false otherwise
  def self.interrupted?
    @interrupted
  end

  def initialize
    @media_files = nil
  end

  def execute
    collection_filepath = File.expand_path(AppConfig[:collection_filespec])
    collection = Collection.new(collection_filepath)

    @media_files = MediaFiles.new(AppConfig[:directories], collection)
    @media_files.titles.each do |title, medias|
      break if DvdProfiler2Xbmc.interrupted?
      medias.each do |media|
        media.load
        media.update if AppConfig[:do_update]
      end
    end

    # set file and directory permissions
    AppConfig[:directories].each { |dir| set_permissions(dir) }
  end

  # generate the report.
  # Note, must be ran after execute()
  # returns an array of lines
  def report
    buf = []
    unless DvdProfiler2Xbmc.interrupted?
      unless @media_files.nil?
        duplicates = duplicates_report
        unless duplicates.empty?
          buf << "Duplicates:\n"
          buf += duplicates
        end

        missing_isbns = missing_isbn_report
        unless missing_isbns.empty?
          buf << ''
          buf += missing_isbns
        end

        missing_imdb_ids = missing_imdb_ids_report
        unless missing_imdb_ids.empty?
          buf << ''
          buf += missing_imdb_ids
        end

        missing_thumbnails = missing_thumbnails_report
        unless missing_thumbnails.empty?
          buf << ''
          buf += missing_thumbnails
        end
      end
    end
    buf
  end

  protected

  # set the directory and file permissions for all files and directories under
  # the given directory
  def set_permissions(dir)
    Dir.glob(File.join(dir, '**/*')).each do |f|
      begin
        if File.directory?(f)
          File.chmod(AppConfig[:dir_permissions], f) unless AppConfig[:dir_permissions].nil?
        else
          File.chmod(AppConfig[:file_permissions], f) unless AppConfig[:file_permissions].nil?
        end
      rescue Exception => e
        AppConfig[:logger].error {e.to_s}
      end
    end
  end

  # duplicate media file report
  def duplicates_report
    buf = []
    duplicates = @media_files.duplicate_titles
    unless duplicates.empty?
      duplicates.each do |title, medias|
        if medias.length > 1
          buf << title
          medias.each {|media| buf << "  #{media.media_path}"}
        end
      end
    end
    buf
  end

  # unable to find ISBN for these titles report
  def missing_isbn_report
    buf = []
    @media_files.titles.each do |title, medias|
      if medias.nil?
        buf << "No media for #{title}"
      else
        if medias[0].isbn.nil?
          paths = []
          medias.each do |media|
            unless File.exist? media.path_to(:no_isbn_extension)
              paths << "  #{media.media_path}"
            end
          end
          unless paths.empty?
            buf << "Missing ISBN for #{title}"
#             buf += paths
          end
        end
      end
    end
    buf
  end

  def missing_imdb_ids_report
    buf = []
    @media_files.titles.each do |title, medias|
      if medias.nil?
        buf << "No media for #{title}"
      else
        medias.each do |media|
          if media.imdb_id.blank?
            buf << "Missing IMDB id for #{title}"
            break
          end
        end
      end
    end
    buf
  end

  def missing_thumbnails_report
    buf = []
    @media_files.titles.each do |title, medias|
      if medias.nil?
        buf << "No media for #{title}"
      else
        medias.each do |media|
          thumbnail = media.path_to(:thumbnail_extension)
          unless File.exist?(thumbnail)
            buf << "Missing thumbnail image #{thumbnail}"
          end
        end
      end
    end
    buf
  end

end

