class TmdbMovie

  attr_reader :query, :document

  API_KEY = '7a2f6eb9b6aa01651000f0a9324db835'

  def initialize(ident)
    @imdb_id = 'tt' + ident.gsub(/^tt/, '') unless ident.blank?
    @query = "http://api.themoviedb.org/2.0/Movie.imdbLookup?imdb_id=#{@imdb_id}&api_key=#{API_KEY}"
  end

  def fanarts
    result = []
    begin
      document['moviematches'].each do |moviematches|
        moviematches['movie'].each do |movie|
          backdrop = movie['backdrop']
          unless backdrop.blank?
            result += backdrop
          end
        end
      end
    rescue
    end
    result
  end

  def posters
    result = []
    begin
      document['moviematches'].each do |moviematches|
        moviematches['movie'].each do |movie|
          result += movie['poster']
        end
      end
    rescue
    end
    result
  end

  def idents
    document['moviematches'].first['movie'].first['id']  rescue nil
  end

  def urls
    document['moviematches'].first['movie'].first['url']  rescue nil
  end

  def imdb_ids
    document['moviematches'].first['movie'].first['imdb']  rescue nil
  end

  def titles
    document['moviematches'].first['movie'].first['title']  rescue nil
  end

  def short_overviews
    document['moviematches'].first['movie'].first['short_overview']  rescue nil
  end

  def types
    document['moviematches'].first['movie'].first['type']  rescue nil
  end

  def alternative_titles
    document['moviematches'].first['movie'].first['alternative_title']  rescue nil
  end

  def releases
    document['moviematches'].first['movie'].first['release']  rescue nil
  end

  def scores
    document['moviematches'].first['movie'].first['score']  rescue nil
  end

  def to_hash
    hash = {}
    [:fanarts, :posters, :idents, :urls, :imdb_ids, :titles, :short_overviews,
     :types, :alternative_titles, :releases, :scores
    ].each do |sym|
      begin
        value = send(sym.to_s)
        hash[sym.to_s] = value unless value.nil?
      rescue Exception => e
        puts "Error getting data for hash for #{sym} - #{e.to_s}"
      end
    end
    hash
  end



  def to_xml
    XmlSimple.xml_out(document, 'NoAttr' => true, 'RootName' => 'movie')
  end

  def to_yaml
    YAML.dump(document)
  end

  private

  MAX_ATTEMPTS = 3
  SECONDS_BETWEEN_RETRIES = 1.0

  # Fetch the document with retry to handle the occasional glitches
  def document
    attempts = 0
    begin
      if @document.nil?
        xml = {}
        if TmdbProfile::use_html_cache
          begin
            filespec = self.query.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
            xml = open(filespec).read
          rescue Exception
            xml = open(self.query).read
            cache_html_files(xml)
          end
        else
          xml = open(self.query).read
        end
        @document = XmlSimple.xml_in(xml) unless xml.blank?
        @document = nil if @document['totalResults'].first == '0'
      end
    rescue Exception => e
      attempts += 1
      if attempts > MAX_ATTEMPTS
        raise
      else
        sleep SECONDS_BETWEEN_RETRIES
        retry
      end
    end
    @document
  end

  # this is used to save imdb pages so they may be used by rspec
  def cache_html_files(html)
    begin
      filespec = self.query.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
      unless File.exist?(filespec)
        puts "caching #{filespec}"
        File.mkdirs(File.dirname(filespec))
        File.open(filespec, 'w') { |f| f.puts html }
      end
    rescue Exception => eMsg
      puts eMsg.to_s
    end
  end
end
