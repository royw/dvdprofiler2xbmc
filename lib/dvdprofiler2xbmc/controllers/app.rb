# == Synopsis
# Transfer media meta data from DvdProfiler to the format that XBMC needs it (.tbn and .nfo files)
#
# usage:
#  app = DvdProfiler2Xbmc.new
#  app.execute
#  app.report.each {|line| puts line}
class DvdProfiler2Xbmc
  include Singleton

  protected

  # == Synopsis
  # protected initializer because it is a Singleton class
  def initialize
    @media_files = nil
    @duplicate_titles = []
  end

  public

  @interrupted = false
  @interrupt_message = "control-C detected, finishing current task"
  @multiple_profiles = []

  class << self
    # == Synopsis
    # When ^C is pressed, this message is sent to stdout
    attr_accessor :interrupt_message

    # == Synopsis
    # An Array of Strings that the external processing my write to to
    # indicate that a given title has multiple ISBNs.
    # HACK, this is a hack because I didn't see a way to cleanly pass
    # the data up from the processing.
    attr_accessor :multiple_profiles
  end

  # == Synopsis
  # A trap("INT") in the Runner calls this to indicate that a ^C has been detected.
  # Note, once set, it is never cleared
  def self.interrupt
    AppConfig[:logger].error { @interrupt_message }
    @interrupted = true
  end

  # == Synopsis
  # Long loops should poll this method to see if they should abort
  # Returns:: true if the application has trapped an "INT", false otherwise
  def self.interrupted?
    @interrupted
  end

  # == Synopsis
  # the application's main execution loop that processes all of the media
  def execute
    AppConfig[:logger].info { "Media Directories:\n  #{AppConfig[:directories].join("\n  ")}" }

    DvdprofilerProfile.collection_filespec = AppConfig[:collection_filespec]

    @media_files = MediaFiles.new(AppConfig[:directories])
    if AppConfig[:do_update]
      @media_files.titles.each do |title, medias|
        break if DvdProfiler2Xbmc.interrupted?
        medias.each do |media|
          # note, NfoController update must be first as it sets isbn and imdb_id for media
          NfoController.update(media)
          ThumbnailController.update(media)
          FanartController.update(media)
        end
      end
    end
    @duplicate_titles = @media_files.duplicate_titles

    # set file and directory permissions
    AppConfig[:directories].each { |dir| set_permissions(dir) }
  end

  # == Synopsis
  # generate the report.
  # Note, must be ran after execute()
  # returns an array of lines
  def report
    buf = []
    unless DvdProfiler2Xbmc.interrupted?
      unless @media_files.nil?
        buf += gen_report('duplicates', 'Duplicates')
        buf += gen_report('missing_isbns', 'Missing ISBNs')
        buf += gen_report('missing_imdb_ids', 'Missing IMDB IDs')
        buf += gen_report('missing_thumbnails', 'Missing Thumbnails')
        buf += gen_report('multiple_profiles', 'Multiple Profiles Found For Single Titles')
      end
    end
    buf
  end

  # == Synopsis
  # utility method that saves the given data to the filespec safely by:
  # 1) writes the data to a new file,
  # 2) deletes any previous backup file,
  # 3) renames the old file to a backup,
  # 4) renames the new file to the original filename.
  def self.save_to_file(filespec, data)
    new_filespec = filespec + AppConfig[:extensions][:new]
    File.open(new_filespec, "w") do |file|
      file.puts(data)
    end
    backup_filespec = filespec + AppConfig[:extensions][:backup]
    File.delete(backup_filespec) if File.exist?(backup_filespec)
    File.rename(filespec, backup_filespec) if File.exist?(filespec)
    File.rename(new_filespec, filespec)
    File.delete(new_filespec) if File.exist?(new_filespec)
  end

  # == Synopsis
  # options hash may have the following:
  #  :extension  - an extension to append to the generated filespec
  #  :year       - the production year
  #  :resolution - the video resolution
  def self.generate_filespec(media_pathspec, type, options={})
    filespec = nil
    begin
      basespec = File.basename(media_pathspec, ".*").gsub(AppConfig[:part_regex], '')
      dirname = File.dirname(media_pathspec)
      part = :no_part
      if media_pathspec =~ AppConfig[:part_regex]
        part = :part
      end

      extension = AppConfig[:extensions][type]
      year = options[:year] || ''
      resolution = options[:resolution] || ''

      if AppConfig[:naming][type].nil?
        filespec = File.join(dirname, basespec)
        unless extension.blank?
          filespec += extension
        end
      else
        format_str = AppConfig[:naming][type][part]
        unless format_str.blank?
          unless extension.blank?
            filespec = File.join(dirname, format_str.gsub(/%t/, basespec).gsub(/%e/, extension).gsub(/%r/, resolution).gsub(/%y/, year))
          end
        end
      end
      unless options[:extension].blank?
        filespec += options[:extension]
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error in generate_filespec(#{media_pathspec}, #{type}, #{options.inspect}) - #{e.to_s}" }
    end
    filespec
  end

  protected

  # == Synopsis
  def gen_report(name, heading='')
    buf = []
    begin
      lines = send("#{name}_report")
      unless lines.empty?
        buf << ''
        buf << heading
        buf += lines
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error generating #{name} report - #{e.to_s}" }
    end
    buf
  end

  # == Synopsis
  # set the directory and file permissions for all files and directories under
  # the given directory
  def set_permissions(dir)
    Dir.glob(File.join(dir, '**/*')).each do |f|
      begin
        if File.directory?(f)
          File.chmod(AppConfig[:dir_permissions].to_i(8), f) unless AppConfig[:dir_permissions].nil?
        else
          File.chmod(AppConfig[:file_permissions].to_i(8), f) unless AppConfig[:file_permissions].nil?
        end
      rescue Exception => e
        AppConfig[:logger].error {e.to_s}
      end
    end
  end

  # == Synopsis
  # duplicate media file report
  def duplicates_report
    buf = []
    unless @duplicate_titles.empty?
      @duplicate_titles.each do |title, medias|
        if medias.length > 1
          buf << title
          medias.each {|media| buf << "  #{media.media_path}"}
        end
      end
    end
    buf
  end

  # == Synopsis
  # unable to find ISBN for these titles report
  def missing_isbns_report
    buf = []
    @media_files.titles.each do |title, medias|
      if medias.nil?
        buf << "No media for #{title}"
      else
        if medias[0].isbn.nil?
          paths = []
          medias.each do |media|
            unless File.exist? media.path_to(:no_isbn)
              paths << "  #{media.media_path}"
            end
          end
          unless paths.empty?
            buf += paths
          end
        end
      end
    end
    buf
  end

  # == Synopsis
  def missing_imdb_ids_report
    buf = []
    @media_files.titles.each do |title, medias|
      if medias.nil?
        buf << "No media for #{title}"
      else
        medias.each do |media|
          if media.imdb_id.blank?
            buf << "  #{title}"
            break
          end
        end
      end
    end
    buf
  end

  # == Synopsis
  def missing_thumbnails_report
    buf = []
    @media_files.titles.each do |title, medias|
      if medias.nil?
        buf << "No media for #{title}"
      else
        medias.each do |media|
          thumbnail = media.path_to(:thumbnail)
          unless File.exist?(thumbnail)
            buf << "  #{thumbnail} #{media.imdb_id.nil? ? '' : media.imdb_id}"
          end
        end
      end
    end
    buf
  end

  # == Synopsis
  def multiple_profiles_report
    @multiple_profiles
  end

end

