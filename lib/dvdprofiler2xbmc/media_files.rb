# == Synopsis
# encapsulation of all media files
class MediaFiles
  attr_reader :medias, :titles, :duplicate_titles

  # given:
  # directories Array of String directory pathspecs
  def initialize(directories, collection)
    @collection = collection
    @medias = find_medias(directories)
    @titles = find_titles(@medias)
    @duplicate_titles = find_duplicate_titles(@titles)
  end

  protected

  # find all the media files in the given set of directories
  def find_medias(directories)
    medias = []
    directories.each do |dir|
      Dir.chdir(dir)
      medias += Dir.glob("**/*.{#{AppConfig[:media_extensions].join(',')}}").collect do |filename|
        Media.new(dir, filename, @collection)
      end
    end
    medias
  end

  # return a hash where the key is the media's title and
  # the value is an Array of Media instances
  def find_titles(medias)
    titles = {}
    medias.each do |media|
      title = media.title_with_year
      titles[title] ||= []
      titles[title] << media
    end
    titles
  end

  # find duplicate titles and return them in a hash
  # where the key is the title and the value is an
  # array of Media objects
  def find_duplicate_titles(titles)
    duplicates = {}
    titles.each do |title, medias|
      base_medias = medias.collect{|media| media.path_to(:base) }.uniq
      if base_medias.length > 1
        duplicates[title] = medias
      end
    end
    duplicates
  end

end

