# == Synopsis
# encapsulation of all media files
class MediaFiles
  attr_reader :medias, :titles

  # given:
  # directories Array of String directory pathspecs
  def initialize(directories)
    @medias = []
    directories.each do |dir|
      Dir.chdir(dir)
      @medias += Dir.glob("**/*.{#{AppConfig[:media_extensions].join(',')}}").collect do |filename|
        Media.new(dir, filename)
      end
    end
    @titles = {}
    @medias.each do |media|
      title = media.title_with_year
      @titles[title] ||= []
      @titles[title] << media
    end
  end


  # find duplicate titles and return them in a hash
  # where the key is the title and the value is an
  # array of Media objects
  def duplicate_titles
    duplicates = {}
    @titles.each do |title, medias|
      base_medias = medias.collect{|media| media.path_to(:base) }.uniq
      if base_medias.length > 1
        duplicates[title] = medias
      end
    end
    duplicates
  end
end

