# This is the model for the IDMB profile which is used
# to find ImdbMovie meta data from either online or from
# a cached file.
#
# Usage:
#
# profiles = ImdbProfile.all(:titles => ['The Alamo'])
#
# profile = ImdbProfile.first(:imdb_id => 'tt0123456')
# or
# profile = ImdbProfile.first(:titles => ['movie title 1', 'movie title 2',...]
#                             :media_years => ['2000'],
#                             :production_years => ['1999'],
#                             :released_years => ['2002', '2008']
#                             :filespec => media.path_to(:imdb_xml))
# puts profile.movie['key'].first
# puts profile.to_xml
# puts profile.imdb_id
#
class ImdbProfile

  # options:
  #   :imdb_id => self.imdb_id,
  #   :titles => titles,
  #   :media_years => [@media.year.to_i],
  #   :production_years => @dvd_hash[:productionyear],
  #   :released_years => @dvd_hash[:released]
  # returns Array of ImdbProfile instances
  def self.all(options={})
    AppConfig[:logger].info { "ImdbProfile.all(#{options.inspect})" }
    result = []
    if has_option?(options, :imdb_id) || (has_option?(options, :filespec) && File.exist?(options[:filespec]))
      result << ImdbProfile.new(options[:imdb_id], options[:filespec])
    elsif has_option?(options, :titles)
      result += self.lookup(options[:titles],
                            options[:media_years],
                            options[:production_years],
                            options[:released_years]
                          ).collect{|ident| ImdbProfile.new(ident, options[:filespec])}
    end
    result
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

  def self.has_option?(options, key)
    options.has_key?(key) && !options[key].blank?
  end

  def initialize(ident, filespec=nil)
    @imdb_id = ident
    @filespec = filespec
    load
  end

  public

  attr_reader :imdb_id, :movie

  def to_xml
    xml = ''
    unless @movie.blank?
      @movie.delete_if { |key, value| value.nil? }
      xml = XmlSimple.xml_out(@movie, 'NoAttr' => true, 'RootName' => 'movie')
    end
    xml
  end

  protected

  # @movie keys => [:title, :directors, :poster_url, :tiny_poster_url, :poster,
  #                 :rating, :cast_members, :writers, :year, :genres, :plot,
  #                 :tagline, :aspect_ratio, :length, :release_date, :countries,
  #                 :languages, :color, :company, :photos, :raw_title,
  #                 :release_year, :also_known_as, :mpaa, :certifications]
  # returns Hash or nil
  def load
    if !@filespec.blank? && File.exist?(@filespec)
      AppConfig[:logger].debug { "loading movie filespec=> #{@filespec.inspect}" }
      @movie = from_xml(open(@filespec).read)
    elsif !@imdb_id.blank?
      AppConfig[:logger].debug { "loading movie from imdb.com, filespec=> #{@filespec.inspect}" }
      @movie = ImdbMovie.new(@imdb_id.gsub(/^tt/, '')).to_hash
      @movie['id'] = 'tt' + @imdb_id.gsub(/^tt/, '') unless @movie.blank?
      save(@filespec) unless @filespec.blank?
    end
    unless @movie.blank?
      @imdb_id = @movie['id']
    else
      @movie = nil
    end
  end

  def from_xml(xml)
    begin
      movie = XmlSimple.xml_in(xml)
    rescue Exception => e
      AppConfig[:logger].warn { "Error converting from xml: #{e.to_s}" }
      movie = nil
    end
    movie
  end

  def save(filespec)
    begin
      xml = self.to_xml
      unless xml.blank?
        AppConfig[:logger].debug { "saving #{filespec}" }
        DvdProfiler2Xbmc.save_to_file(filespec, xml)
      end
    rescue Exception => e
      AppConfig[:logger].error "Unable to save imdb profile to #{filespec} - #{e.to_s}"
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

    titles.flatten.uniq.compact.each do |title|
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
    AppConfig[:logger].debug { "IMDB id => #{idents.join(', ')}" } unless idents.blank?
    idents
  end
end
