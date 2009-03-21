# add some methods to ImdbMovie

class ImdbMovie

  # return the raw title
  def raw_title
    document.at("h1").innerText
  end

  # is this a video game as indicated by a '(VG)' in the raw title?
  def video_game?
    raw_title =~ /\(VG\)/
  end

  # find the release year
  # Note, this is needed because not all entries on IMDB have a full
  # release date as parsed by release_date.
  def release_year
    document.search("//h5[text()^='Release Date']/..").innerHTML[/\d{4}/]
  end

  # return an Array of Strings containing AKA titles
  def also_known_as
    el = document.search("//h5[text()^='Also Known As:']/..").at('h5')
    aka = []
    while(!el.nil?)
      aka << el.to_s unless el.elem?
      el = el.next
    end
    aka.collect!{|a| a.gsub(/\([^\)]*\)/, '').strip}
    aka.uniq!
    aka.collect!{|a| a.blank? ? nil : a}
    aka.compact
  end

  # The MPAA rating, i.e. "PG-13"
  def mpaa
    document.search("//h5[text()^='MPAA']/..").text.gsub('MPAA:', '').strip rescue nil
  end

  # older films may not have MPAA ratings but usually have a certification.
  # return a hash with country abbreviations for keys and the certification string for the value
  # example:  {'USA' => 'Approved'}
  def certifications
    cert_hash = {}
    certs = document.search("h5[text()='Certification:'] ~ a[@href*=/List?certificates']").map { |link| link.innerHTML.strip } rescue []
    certs.each { |line| cert_hash[$1] = $2 if line =~ /(.*):(.*)/ }
    cert_hash
  end

  private

  MAX_ATTEMPTS = 3
  SECONDS_BETWEEN_RETRIES = 1

  # replace the document handler with one that will retry to handle
  # the occasional glitches
  def document
    attempts = 0
    begin
      @document ||= Hpricot(open(self.url).read)
    rescue Exception => e
      attempts += 1
      if attempts > MAX_ATTEMPTS
        AppConfig[:logger].error{ "Error reading IMDB page (#{self.url}) - #{e.to_s}"}
        raise
      else
        sleep SECONDS_BETWEEN_RETRIES
        retry
      end
    end
  end

end

class ImdbSearch
  # Find the IMDB ID for the current search title
  # The find can be helped a lot by including a years option that contains
  # an Array of integers that are the production year (plus/minus a year)
  # and the release year.
  def find_id(options={})
    id = nil
    found_movies = self.movies
    unless found_movies.nil?
      desired_movies = found_movies.select do |m|
      aka = m.also_known_as
      result = imdb_compare_titles(m.title, aka, @query) && !m.video_game? && !m.release_year.blank?
      if result
        AppConfig[:logger].debug { m.title }
        AppConfig[:logger].debug { "m.release_year => #{m.release_year}" }
        unless options[:years].blank?
          result = options[:years].include?(m.release_year.to_i)
        end
      end
      result
      end
      ids = desired_movies.collect{|m| m.id}.uniq.compact
      if ids.length == 1
      id = "tt#{ids[0]}"
      else
        AppConfig[:logger].debug { options[:media_path] } unless options[:media_path].nil?
        AppConfig[:logger].debug { options[:years].pretty_inspect }
        desired_movies.collect{|m| [m.raw_title, m.id, m.title, m.url, m.release_year.blank? ? 'no release date' : m.release_year]}.uniq.compact.each do |m|
          AppConfig[:logger].debug { m.pretty_inspect }
        end
      end
    end
    id
  end

  protected

  # compare the imdb title and the imdb title's AKAs against the media title.
  # note, on exact match lookups, IMDB will sometimes set the title to
  # 'trailers and videos' instead of the correct title.
  def imdb_compare_titles(imdb_title, aka_titles, media_title)
    result = fuzzy_compare_titles(imdb_title, media_title)
    unless result
      result = fuzzy_compare_titles(imdb_title, 'trailers and videos')
      unless result
        aka_titles.each do |aka|
          result = fuzzy_compare_titles(aka, media_title)
          break if result
        end
      end
    end
    result
  end

  # a fuzzy compare that is case insensitive and replaces '&' with 'and'
  # (because that is what IMDB occasionally does)
  def fuzzy_compare_titles(title1, title2)
    t1 = title1.downcase
    t2 = title2.downcase
    (t1 == t2) ||
    (t1.gsub(/&/, 'and') == t2.gsub(/&/, 'and')) ||
    (t1.gsub(/[-:]/, ' ') == t2.gsub(/[-:]/, ' ')) ||
    (t1.gsub('more at imdbpro ?', '') == t2)
  end
end

