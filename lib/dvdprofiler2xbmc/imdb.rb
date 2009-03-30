
class Imdb
  def initialize
    @cache = {}
  end

  def first(titles, media_years, production_years, released_years)
    lookup(titles, media_years, production_years, released_years).first
  end

  def all(titles, media_years, production_years, released_years)
    lookup(titles, media_years, production_years, released_years)
  end

  protected

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
  def lookup(titles, media_years, production_years, released_years)
    idents = []
    year_sets = []
    year_sets << media_years unless media_years.empty?
    year_sets << fuzzy_years(production_years, 0)
    year_sets << fuzzy_years(production_years, -1..1)
    year_sets << fuzzy_years(released_years, 0)
    year_sets << fuzzy_years(released_years, -1..1)
    year_sets << [] if media_years.empty?

    titles.each do |title|
      [false, true].each do |search_akas|
        AppConfig[:logger].debug { (search_akas ? 'Search AKAs' : 'Do not search AKAs') }
        imdb_search = ImdbSearch.new(title, search_akas)
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
  def fuzzy_years(source_years, fuzzy)
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
  def find_id(imdb_search, title, years, search_akas)
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
#           if movies.size == 1
#             idents = [movies.first.id.to_s]
#           elsif movies.size > 1
#             AppConfig[:logger].debug { "Multiple titles found (#{movies.collect{|m| [m.id, m.year, m.title]}.inspect})"}
#           end
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
