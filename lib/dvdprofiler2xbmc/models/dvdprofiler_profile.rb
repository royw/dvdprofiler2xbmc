
class DvdprofilerProfile

  # options:
  #  :isbn => String
  #  :title => String
  # returns:  Array of DvdprofilerProfile instances
  def self.all(options={})
    # :isbn_dvd_hash, :title_isbn_hash, :isbn_title_hash
    result = []

    # try finding by isbn first
    if options.has_key?(:isbn) && !options[:isbn].blank?
      dvd_hash = collection.isbn_dvd_hash[options[:isbn]]
      unless dvd_hash.blank?
        result << DvdprofilerProfile.new(dvd_hash, options[:isbn])
      end
    end

    # if unable to find by isbn, then try finding by title
    if result.empty? && options.has_key?(:title)
      isbns = self.find_isbns(options)
      unless isbns.blank?
        isbns.each do |isbn|
          dvd_hash = collection.isbn_dvd_hash[isbn]
          unless dvd_hash.blank?
            result << DvdprofilerProfile.new(dvd_hash, isbn, options[:title])
          end
        end
      end
    end

    # return all profiles if neither :isbn nor :title are given
    if result.empty? && !options.has_key?(:isbn) && !options.has_key?(:title)
      collection.isbn_dvd_hash.each do |isbn, dvd_hash|
        result << DvdprofilerProfile.new(dvd_hash, isbn)
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

  private

  def self.collection
    @collection ||= Collection.new(File.expand_path(AppConfig[:collection_filespec]))
  end

  protected

  def initialize(dvd_hash, isbn, title=nil)
    @dvd_hash = dvd_hash
    @isbn = isbn
    @title = title
    @title ||= @dvd_hash[:title]
  end

  public

  attr_reader :isbn, :title, :dvd_hash

  def to_xml
    data = @dvd_hash.stringify_keys
    xml = XmlSimple.xml_out(data, 'NoAttr' => true, 'RootName' => 'movie')
  end

  def save(filespec)
    begin
      xml = self.to_xml
      unless xml.blank?
        AppConfig[:logger].debug { "saving #{filespec}" }
        save_to_file(filespec, xml)
      end
    rescue Exception => e
      AppConfig[:logger].error { "Unable to save dvdprofiler profile to #{filespec} - #{e.to_s}" }
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

end