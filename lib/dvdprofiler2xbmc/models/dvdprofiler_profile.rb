# This is the model for the DVD Profiler profile which is used
# to find meta data from DVD Profiler's exported Collection.xml
#
# Usage:
#
# profiles = DvdprofilerProfile.all(:titles => ['The Alamo'])
#
# profile = DvdprofilerProfile.first(:isbn => '012345678901')
# or
# profile = DvdprofilerProfile.first(:title => 'movie title')
#
# puts profile.dvd_hash[:key]
# puts profile.to_xml
# puts profile.isbn
# puts profile.title
# profile.save(media.path_to(:dvdprofiler_xml))
#
class DvdprofilerProfile

  # options:
  #  :isbn => String
  #  :title => String
  #  :logger => nil or logger instance
  # returns:  Array of DvdprofilerProfile instances
  def self.all(options={})
    # :isbn_dvd_hash, :title_isbn_hash, :isbn_title_hash
    result = []

    # try finding by isbn first
    if options.has_key?(:isbn) && !options[:isbn].blank?
      dvd_hash = collection.isbn_dvd_hash[options[:isbn]]
      unless dvd_hash.blank?
        result << DvdprofilerProfile.new(dvd_hash, options[:isbn], options[:title], options[:logger])
      end
    end

    # if unable to find by isbn, then try finding by title
    if result.empty? && options.has_key?(:title)
      isbns = self.find_isbns(options)
      unless isbns.blank?
        isbns.each do |isbn|
          dvd_hash = collection.isbn_dvd_hash[isbn]
          unless dvd_hash.blank?
            unless options[:year].blank?
              if dvd_hash[:productionyear].include? options[:year]
                result << DvdprofilerProfile.new(dvd_hash, isbn, options[:title], options[:logger])
              end
            else
              result << DvdprofilerProfile.new(dvd_hash, isbn, options[:title], options[:logger])
            end
          end
        end
      end
    end

    # return all profiles if neither :isbn nor :title are given
    if result.empty? && !options.has_key?(:isbn) && !options.has_key?(:title)
      collection.isbn_dvd_hash.each do |isbn, dvd_hash|
        result << DvdprofilerProfile.new(dvd_hash, isbn, nil, options[:logger])
      end
    end

    result
  end

  # options:
  #  :isbn => String
  #  :title => String
  # returns:  DvdprofilerProfile instance or nil
  def self.first(options={})
    all(options).first
  end

  # look up ISBN by title
  # expects a :title option
  # returns Array of ISBN Strings
  def self.find_isbns(options={})
    result = []
    if options.has_key?(:title)
      result = [collection.title_isbn_hash[Collection.title_pattern(options[:title])]].flatten.uniq.compact
    end
    result
  end

  class << self
    @collection_filespec = 'Collection.xml'
    attr_accessor :collection_filespec
  end

  protected

  def self.collection
    @collection ||= Collection.new(File.expand_path(@collection_filespec))
  end

  def initialize(dvd_hash, isbn, title, logger)
    @dvd_hash = dvd_hash
    @isbn = isbn
    @title = title
    @title ||= @dvd_hash[:title]
    @logger = OptionalLogger.new(logger)
  end

  public

  attr_reader :isbn, :title, :dvd_hash

  def to_xml
    data = @dvd_hash.stringify_keys
    data.delete_if { |key, value| value.nil? }
    xml = XmlSimple.xml_out(data, 'NoAttr' => true, 'RootName' => 'movie')
  end

  def save(filespec)
    begin
      xml = self.to_xml
      unless xml.blank?
        @logger.debug { "saving #{filespec}" }
        DvdProfiler2Xbmc.save_to_file(filespec, xml)
      end
    rescue Exception => e
      @logger.error { "Unable to save dvdprofiler profile to #{filespec} - #{e.to_s}" }
    end
  end

  def save_to_file(filespec, data)
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
