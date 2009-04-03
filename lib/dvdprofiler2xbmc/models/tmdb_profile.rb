class TmdbProfile

  # options:
  #  :imdb_id => String (either with or without leading 'tt')
  def self.all(options={})
    result = []
    if options.has_key?(:imdb_id)
      result << TmdbProfile.new(options[:imdb_id])
    end
    result
  end

  def self.first(options={})
    self.all(options).first
  end

  # this is intended to be stubed by rspec where it
  # should return true.
  def self.use_html_cache
    false
  end

  protected

  API_KEY = '7a2f6eb9b6aa01651000f0a9324db835'

  def initialize(ident)
    @imdb_id = 'tt' + ident.gsub(/^tt/, '') unless ident.blank?
    @query = "http://api.themoviedb.org/2.0/Movie.imdbLookup?imdb_id=#{@imdb_id}&api_key=#{API_KEY}"
  end


  public

  attr_reader :query

  def fanarts
    result = []
    document['moviematches'].each do |moviematches|
      moviematches['movie'].each do |movie|
        result += movie['backdrop']
      end
    end
    result
  end

  def posters
    result = []
    document['moviematches'].each do |moviematches|
      moviematches['movie'].each do |movie|
        result += movie['poster']
      end
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

  def to_xml
    XmlSimple.xml_out(document, 'NoAttr' => true, 'RootName' => 'movie')
  end

  def to_yaml
    YAML.dump(document)
  end

  def save(filespec)
    begin
      xml = self.to_xml
      unless xml.blank?
        AppConfig[:logger].debug { "saving #{filespec}" }
        save_to_file(filespec, xml)
      end
    rescue Exception => e
      AppConfig[:logger].error "Unable to save tmdb profile to #{filespec} - #{e.to_s}"
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

  private

  MAX_ATTEMPTS = 3
  SECONDS_BETWEEN_RETRIES = 1.0

  # Fetch the document with retry to handle the occasional glitches
  def document
    attempts = 0
    begin
      if @document.nil?
        xml = ''
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
        @document = XmlSimple.xml_in(xml)
#         pp @document
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
