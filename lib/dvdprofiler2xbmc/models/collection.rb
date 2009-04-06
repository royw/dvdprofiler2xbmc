# == Synopsis
# This model encapsulates the DVDProfiler Collection.xml
class Collection
  # various regexes used to clean up a title for matching purposes.
  # used in TITLE_REPLACEMENTS hash below
  PUNCTUATION = /[\?\:\!\"\'\,\.\-\/\*]/
  HTML_ESCAPES = /\&[a-zA-Z]+\;/
  SQUARE_BRACKET_ENCLOSURES = /\[.*?\]/
  PARENTHESIS_ENCLOSURES = /\(.*?\)/
  MULTIPLE_WHITESPACES= /\s+/
  STANDALONE_AMPERSAND = /\s\&\s/
  WIDESCREEN = /widescreen/i
  SPECIAL_EDITION = /special edition/i

  # array of hashes is intentional as the order is critical
  # the enclosures [...] & (...) must be removed first,
  # then " & " must be replaced by " and ",
  # then html escapes &...; must be replaced by a space,
  # then remaining punctuation is replacesed by a space,
  # finally multiple whitespaces are reduced to single whitespace
  TITLE_REPLACEMENTS = [
    { SQUARE_BRACKET_ENCLOSURES => ''      },
    { PARENTHESIS_ENCLOSURES    => ''      },
    { STANDALONE_AMPERSAND      => ' and ' },
    { HTML_ESCAPES              => ' '     },
    { WIDESCREEN                => ' '     },
    { SPECIAL_EDITION           => ' '     },
    { PUNCTUATION               => ' '     },
    { MULTIPLE_WHITESPACES      => ' '     },
  ]

  attr_reader :isbn_dvd_hash, :title_isbn_hash, :isbn_title_hash

  @filespec = nil

  def initialize(filename = 'Collection.xml')
    @title_isbn_hash = Hash.new
    @isbn_dvd_hash = Hash.new
    @isbn_title_hash = Hash.new
    @filespec = filename
    reload
    save
  end

  # save as a collection.yaml file unless the existing
  # collection.yaml is newer than the collection.xml
  def save
    unless @filespec.nil?
      yaml_filespec = @filespec.ext('.yaml')
      if !File.exist?(yaml_filespec) || (File.mtime(@filespec) > File.mtime(yaml_filespec))
        AppConfig[:logger].info { "saving: #{yaml_filespec}" }
        File.open(yaml_filespec, "w") do |f|
          YAML.dump(
            {
              :title_isbn_hash => @title_isbn_hash,
              :isbn_title_hash => @isbn_title_hash,
              :isbn_dvd_hash => @isbn_dvd_hash,
            }, f)
        end
      else
        AppConfig[:logger].info { "not saving, yaml file is newer than xml file" }
      end
    else
      AppConfig[:logger].error { "can not save, the filespec is nil" }
    end
  end

  # load the collection from the collection.yaml if it exists,
  # otherwise from the collection.xml
  def reload
    @title_isbn_hash.clear
    @isbn_dvd_hash.clear
    @isbn_title_hash.clear
    collection = Hash.new
    yaml_filespec = @filespec.ext('.yaml')
    if File.exist?(yaml_filespec) && (File.mtime(yaml_filespec) > File.mtime(@filespec))
      AppConfig[:logger].info { "Loading #{yaml_filespec}" }
      data = YAML.load_file(yaml_filespec)
      @title_isbn_hash = data[:title_isbn_hash]
      @isbn_dvd_hash = data[:isbn_dvd_hash]
      @isbn_title_hash = data[:isbn_title_hash]
    else
      elapsed_time = timer do
        AppConfig[:logger].info { "Loading #{@filespec}" }
        collection = XmlSimple.xml_in(@filespec, { 'KeyToSymbol' => true})
      end
      AppConfig[:logger].info { "XmlSimple.xml_in elapse time: #{elapsed_time.elapsed_time_s}" }
      collection[:dvd].each do |dvd|
        isbn = dvd[:id][0]
        original_title = dvd[:title][0]
        title = Collection.title_pattern(dvd[:title][0])
        unless isbn.blank? || title.blank?
          @title_isbn_hash[title] ||= []
          @title_isbn_hash[title] << isbn
          @isbn_title_hash[isbn] = original_title
          dvd_hash = Hash.new
          dvd_hash[:isbn] = isbn
          dvd_hash[:title] = original_title
          unless dvd[:actors].blank?
            dvd_hash[:actors] = dvd[:actors].compact.collect {|a| a[:actor]}.flatten.compact.collect do |a|
              name = []
              name << a['FirstName'] unless a['FirstName'].blank?
              name << a['MiddleName'] unless a['MiddleName'].blank?
              name << a['LastName'] unless a['LastName'].blank?
              info = Hash.new
              info['name'] = name.join(' ')
              info['role'] = a['Role']
              info
            end
          end
          dvd_hash[:genres] = dvd[:genres].collect{|a| a[:genre]}.flatten unless dvd[:genres].blank?
          dvd_hash[:studios] = dvd[:studios].collect{|a| a[:studio]}.flatten unless dvd[:studios].blank?
          dvd_hash[:productionyear] = [dvd[:productionyear].join(',')] unless dvd[:productionyear].blank?
          dvd_hash[:rating] = [dvd[:rating].join(',')] unless dvd[:rating].blank?
          dvd_hash[:runningtime] = [dvd[:runningtime].join(',')] unless dvd[:runningtime].blank?
          dvd_hash[:released] = [dvd[:released].join(',')] unless dvd[:released].blank?
          dvd_hash[:overview] = [dvd[:overview].join(',')] unless dvd[:overview].blank?
          dvd_hash[:lastedited] = dvd[:lastedited][0] unless dvd[:lastedited].blank?
          directors = find_directors(dvd[:credits])
          dvd_hash[:directors] = directors unless directors.blank?
          @isbn_dvd_hash[isbn] = dvd_hash
        end
      end
    end
  end

  def find_directors(dvd_credits)
    directors = nil
    begin
      dvd[:credits].each do |credits_hash|
        credits_hash[:credit].each do |credit_hash|
          if((credit_hash['CreditType'] == 'Direction') || (credit_hash['CreditSubtype'] == 'Director'))
            name = []
            name << credit_hash['FirstName']  unless credit_hash['FirstName'].blank?
            name << credit_hash['MiddleName'] unless credit_hash['MiddleName'].blank?
            name << credit_hash['LastName']   unless credit_hash['LastName'].blank?
            directors ||= []
            directors << name.join(' ')
          end
        end
      end
    rescue
    end
    directors
  end

  # == Synopsis
  # The titles found between LMCE's Amazon lookup and DVDProfiler sometimes differ in
  # whether or not a prefix of "The", "A", or "An" is included in the title.  Here we
  # create an Array of possible titles with and without these prefix words.
  def Collection.title_permutations(base_title)
    titles = []
    unless base_title.nil? || base_title.empty?
      titles << base_title
      ['the', 'a', 'an'].each do |prefix|
        titles << "#{prefix} " + base_title unless base_title =~ /^#{prefix}\s/
        titles << $1 if base_title =~ /^#{prefix}\s(.*)$/
      end
    end
    titles
  end

  # == Synopsis
  # the titles found between LMCE's Amazon lookup and DVDProfiler quite often differ in the
  # inclusion of punctuation and capitalization.  So we create a pattern of lower case words
  # without punctuation and with single spaces between words.
  def Collection.title_pattern(src_title)
    title = nil
    unless src_title.nil?
      title = src_title.dup
      title.downcase!
      TITLE_REPLACEMENTS.each do |replacement|
        replacement.each do |regex, value|
          title.gsub!(regex, value)
        end
      end
      title.strip!
    end
    title
  end

end

