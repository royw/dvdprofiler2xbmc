
class ImdbProfile

  # options:
  #   :imdb_id => self.imdb_id,
  #   :titles => titles,
  #   :media_years => [@media.year.to_i],
  #   :production_years => @dvd_hash[:productionyear],
  #   :released_years => @dvd_hash[:released]
  # returns Array of ImdbProfile instances
  def self.all(options={})
    self.lookup(options[:titles],
                options[:media_years],
                options[:production_years],
                options[:released_years]
               ).collect{|ident| ImdbProfile.new(ident)}
  end

  # options:
  #   :imdb_id => self.imdb_id,
  #   :titles => titles,
  #   :media_years => [@media.year.to_i],
  #   :production_years => @dvd_hash[:productionyear],
  #   :released_years => @dvd_hash[:released]
  # returns ImdbProfile instance or nil
  def self.first(options={})
    self.all(options).first
  end

  protected

  def initialize(ident)
    @imdb_id = ident
    @movie = nil
  end

  public

  attr_reader :imdb_id

  def movie
    @movie ||= ImdbMovie.new(@imdb_id.gsub(/^tt/, '')) unless @imdb_id.blank?
    @movie
  end

  def to_xml
    xml = ''
    xml = @movie.to_xml unless @movie.blank?
    xml
  end

  def save(filespec)
    begin
      xml = self.to_xml
      save_to_file(filespec, xml) unless xml.blank?
    rescue Exception => e
      AppConfig[:logger].error "Unable to save imdb profile to #{filespec} - #{e.to_s}"
    end
  end

  protected

  def save_to_file(filespec, data)
    new_filespec = filespec + AppConfig[:new_extension]
    File.open(new_filespec, "w") do |file|
      file.puts(data)
    end
    backup_filespec = filespec + AppConfig[:backup_extension]
    File.delete(backup_filespec) if File.exist?(backup_filespec)
    File.rename(filespec, backup_filespec) if File.exist?(filespec)
    File.rename(new_filespec, filespec)
    File.delete(new_filespec) if File.exist?(new_filespec)
  end

  # lookup IMDB title using years as the secondary search key
  # the titles should behave as an Array, the intent here is to be
  # able to try to find the exact title from DVD Profiler and if that
  # fails, to try to find the title pattern
  # The search order is:
  # 1) media_years should be from media filename
  # 2) production years
  # 3) production years plus/minus a year
  # 4) released years
  # 5) released years plus/minus a year
  # 6) no years
  def self.lookup(titles, media_years, production_years, released_years)
    AppConfig[:logger].info { "lookup(#{titles.inspect}, #{media_years.inspect}, #{production_years.inspect}, #{released_years.inspect})" }
    idents = []
    year_sets = []
    year_sets << media_years unless media_years.blank?
    year_sets << fuzzy_years(production_years, 0)
    year_sets << fuzzy_years(production_years, -1..1)
    year_sets << fuzzy_years(released_years, 0)
    year_sets << fuzzy_years(released_years, -1..1)
    year_sets << [] if media_years.blank?

    titles.each do |title|
      [false, true].each do |search_akas|
        AppConfig[:logger].debug { (search_akas ? 'Search AKAs' : 'Do not search AKAs') }
        imdb_search = ImdbSearch.new(title, search_akas)
        @cache ||= {}
        imdb_search.set_cache(@cache)

        year_sets.each do |years|
          new_idents = find_id(imdb_search, title, years, search_akas)
          AppConfig[:logger].debug { "new_idents => #{new_idents.inspect}" }
          idents += new_idents
          break unless new_idents.blank?
        end
        break unless idents.blank?
      end
      break unless idents.blank?
    end
    idents.uniq.compact
  end

  # Different databases seem to mix up released versus production years.
  # So we combine both into a Array of integer years.
  # fuzzy is an integer range, basically expand each known year by the fuzzy range
  # i.e., let production and released year both be 2000 and fuzzy=-1..1,
  # then the returned years would be [1999, 2000, 2001]
  def self.fuzzy_years(source_years, fuzzy)
    years = []
    unless source_years.blank?
      years = [source_years].flatten.collect do |date|
        a = []
        if date.to_s =~ /(\d{4})/
          y = $1.to_i
          a = [*fuzzy].collect do
            |f| y.to_i + f
          end
        end
        a
      end
    end
    result = years.flatten.uniq.compact.sort
    AppConfig[:logger].debug {"fuzzy_years(#{source_years}, #{fuzzy}) => #{result.join(', ')}"}
    result
  end

  # try to find the imdb id for the movie
  def self.find_id(imdb_search, title, years, search_akas)
    idents = []

    AppConfig[:logger].info { "Searching IMDB for \"#{title}\" (#{years.join(", ")})" }
    unless title.blank?
      begin
        movies = imdb_search.movies
        AppConfig[:logger].debug { "movies => (#{movies.collect{|m| [m.id, m.year, m.title]}.inspect})"}
        if movies.size == 1
          idents = [movies.first.id.to_s]
        elsif movies.size > 1
          AppConfig[:logger].debug { "years => #{years.inspect}"}
          same_year_movies = movies.select{ |m| !m.year.blank? && years.include?(m.year.to_i) }
          idents = same_year_movies.collect{|m| m.id.to_s}
          AppConfig[:logger].debug { "same_year_movies => (#{same_year_movies.collect{|m| [m.id, m.year, m.title]}.inspect})"}
        end
      rescue Exception => e
        AppConfig[:logger].error { "Error searching IMDB - " + e.to_s }
        AppConfig[:logger].error { e.backtrace.join("\n") }
      end
    end
    AppConfig[:logger].info { "IMDB id => #{idents.join(', ')}" } unless idents.blank?
    idents
  end
end
