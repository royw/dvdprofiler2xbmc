# This is the model for the themovieDb profile which is used
# to find TmdbMovie meta data from either online or from
# a cached file.
#
# Usage:
#
# profile = TmdbProfile.first(:imdb_id => 'tt0123456')
#
# puts profile.movie['key'].first
# puts profile.to_xml
# puts profile.imdb_id
#
class TmdbProfile

  # options:
  #  :imdb_id  => String (either with or without leading 'tt')
  #  :filespec => nil or a valid pathspec
  #  :logger   => nil or a logger instance
  def self.all(options={})
    result = []
    if has_option?(options, :imdb_id)
      result << TmdbProfile.new(options[:imdb_id], options[:filespec], options[:logger])
    end
    result
  end

  # see TmdbProfile.all for description of options
  def self.first(options={})
    self.all(options).first
  end

#   # this is intended to be stubed by rspec where it
#   # should return true.
#   def self.use_html_cache
#     false
#   end

  protected

  def self.has_option?(options, key)
    options.has_key?(key) && !options[key].blank?
  end

  def initialize(ident, filespec, logger)
    @imdb_id = ident
    @filespec = filespec
    @logger = OptionalLogger(logger)
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

  def load
    @movie = nil
    if !@filespec.blank? && File.exist?(@filespec)
      @logger.debug { "loading movie filespec=> #{@filespec.inspect}" }
      @movie = from_xml(open(@filespec).read)
    elsif !@imdb_id.blank?
      @logger.debug { "loading movie from tmdb.com, filespec=> #{@filespec.inspect}" }
      @movie = TmdbMovie.new(@imdb_id.gsub(/^tt/, '')).to_hash
      save(@filespec) unless @filespec.blank?
    end
    if @movie.blank?
      @movie = nil
    end
  end

  def from_xml(xml)
    begin
      movie = XmlSimple.xml_in(xml)
    rescue Exception => e
      @logger.warn { "Error converting from xml: #{e.to_s}" }
      movie = nil
    end
    movie
  end

  def save(filespec)
    begin
      xml = self.to_xml
      unless xml.blank?
        @logger.debug { "saving #{filespec}" }
        save_to_file(filespec, xml)
      end
    rescue Exception => e
      @logger.error { "Unable to save tmdb profile to #{filespec} - #{e.to_s}" }
    end
  end

  def self.save_to_file(filespec, data)
    new_filespec = filespec + '.new'
    File.open(new_filespec, "w") do |file|
      file.puts(data)
    end
    backup_filespec = filespec + '~'
    File.delete(backup_filespec) if File.exist?(backup_filespec)
    File.rename(filespec, backup_filespec) if File.exist?(filespec)
    File.rename(new_filespec, filespec)
    File.delete(new_filespec) if File.exist?(new_filespec)
  end
end
