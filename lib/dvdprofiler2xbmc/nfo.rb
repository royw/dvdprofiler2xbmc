# == Synopsis
# NFO (info) files
class NFO
  def initialize(media, dvd_hash)
    @media = media
    @dvd_hash = dvd_hash
    load
  end
  
  # save as a .nfo file, creating a backup if the .nfo already exists
  def save
    begin
      nfo_filespec = @media.media_path.ext(".#{AppConfig[:nfo_extension]}")
      nfo_backup_filespec = @media.media_path.ext(".#{AppConfig[:nfo_backup_extension]}")
      File.delete(nfo_backup_filespec) if File.exist?(nfo_backup_filespec)
      File.rename(nfo_filespec, nfo_backup_filespec) if File.exist?(nfo_filespec)
      File.open(nfo_filespec, "w") do |file|
	file.puts(to_nfo(@dvd_hash))
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error saving nfo file - " + e.to_s }
    end
  end
  
  def load
    begin
      nfo_filespec = @media.media_path.ext(".#{AppConfig[:nfo_extension]}")
      @movie = XmlSimple.xml_in(nfo_filespec) if File.exist? nfo_filespec
    rescue Exception => e
      AppConfig[:logger].error { "Error loading \"#{nfo_filespec}\" - " + e.to_s }
    end
  end
  
  # return a nfo xml String from the given dvd_hash (from Collection)
  def to_nfo(dvd_hash)
    @movie ||= {}
    imdb_id = @movie['id']
    imdb_id = imdb_lookup(dvd_hash) if AppConfig[:imdb_query] && imdb_id.blank?
    @movie['title']         = dvd_hash[:title]
    @movie['mpaa']          = dvd_hash[:rating]
    @movie['year']          = dvd_hash[:productionyear]
    @movie['outline']       = dvd_hash[:overview]
#     @movie['plot']          = dvd_hash[:overview]
    @movie['runtime']       = dvd_hash[:runningtime]
    @movie['genre']         = map_genres((dvd_hash[:genres] + @media.media_subdirs.split('/')).uniq)
    @movie['actor']         = dvd_hash[:actors]
    @movie['id']            = imdb_id unless imdb_id.nil?
    @movie['isbn']          = dvd_hash[:isbn]
  
    begin
      XmlSimple.xml_out(@movie, 'NoAttr' => true, 'RootName' => 'movie')
    rescue Exception => e
      AppConfig[:logger].error { "Error creating nfo file - " + e.to_s }
    end
  end
  
  protected
  
  def map_genres(genres)
    new_genres = []
    genres.each do |genre|
      new_genres << (AppConfig[:genre_maps][genre].nil? ? genre : AppConfig[:genre_maps][genre])
    end
    new_genres.uniq.compact
  end

  # try to find the imdb id for the movie
  def imdb_lookup(dvd_hash)
    id = nil
    AppConfig[:logger].info { "Searching IMDB for \"#{dvd_hash[:title]}\"" }
    unless dvd_hash[:title].blank?
      years = released_years(dvd_hash)
      begin
	imdb_search = ImdbSearch.new(dvd_hash[:title])
	id = imdb_search.find_id(:years => years, :media_path => @media.media_path)
      rescue Exception => e
	AppConfig[:logger].error { "Error searching IMDB - " + e.to_s }
	AppConfig[:logger].error { e.backtrace.join("\n") }
      end
    end
    AppConfig[:logger].info { "IMDB id => #{id}" } unless id.nil?
    id
  end

  # Different databases seem to mix up released versus production years.
  # So we combine both into a Array of integer years.
  def released_years(dvd_hash)
    years = []
    unless dvd_hash[:productionyear].blank?
      years += dvd_hash[:productionyear].collect{|y| [y.to_i - 1, y.to_i, y.to_i + 1]}.flatten
    end
    unless dvd_hash[:released].blank?
      years += dvd_hash[:released].collect do |date|
	y = nil
	y = $1.to_i if date =~ /(\d{4})\-/
	y
      end
    end
    years.flatten.uniq.compact.sort
  end
  
end

