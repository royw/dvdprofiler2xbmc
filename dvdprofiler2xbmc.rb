#!/usr/bin/env ruby18

# == Synopsis
# This script will attempt to match up media files from a set of directories
# to the collection.xml file exported from DVD Profiler.  For matches, the
# script will then create a {moviename}.nfo from the data in collections.xml
# and also copy the front cover image to {moviename}.tbn.  Both files will
# be placed in the same directory as the source media file.
#
# Then on XBMC, set the source content to none to remove the meta data from
# the library, then set the source content back to Movies to import the
# media.  This time, the data in the .nfo files will be used instead of
# scraping.
#
# Notes:
#
# 1) currently you lose a few meta data fields such as Rating and Director
# using this script instead of a scraper.
#
# 2) Currently only supports file based media containers, not directory
# based.
#
# 3) Media filename convention is to take the media's title from DVD Profiler,
# replace any punctuation with a space character, then replace any multiple
# spaces with a single space.  Next remove any leading or trailing spaces.  
# Optionally can append " - YYYY" where YYYY is the movie's release year.  
# Naturally the extension is the media's container type.  Note, you should
# not include in the title edition info like "Widescreen" or "Special Edition"
# eventhough there are some mistakes in the DVD Profiler profiles that do
# include these in the title.
#
# Usage:
# Edit the DIRECTORIES and locations below for your system.
# Then run the script:
#   ruby dvdprofiler2xbmc.rb
#
# Prerequisites:
#   gem install xml-simple
#   gem install porras-imdb
#   gem install log4r
#   gem install commandline
#   gem install mash
#
# License: 
# GPL version 2 (http://www.opensource.org/licenses/gpl-2.0.php)

require 'rubygems'
require 'yaml'
require 'xmlsimple'
require 'ftools'
require 'imdb'
require 'pp'
require 'mash'
require "log4r"
require 'commandline/optionparser'
include CommandLine

module AppConfig
  @config = Mash.new
  @yaml_filespec = File.join(ENV['HOME'], '.dvdprofiler2xbmcrc')
  
  def self.[](k)
    @config[k]
  end
  
  def self.[]=(k,v)
    @config[k] = v
  end
  
  def self.save
    begin
      File.delete(@yaml_filespec) if File.exist?(yaml_filespec)
      AppConfig[:logger].info { "saving: #{yaml_filespec}" }
      File.open(yaml_filespec, "w") do |f|
	YAML.dump(@config, f)
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error saving config file \"#{@yaml_filespec} - " + e.to_s }
    end
  end
  
  def self.load
    begin
      if File.exist?(@yaml_filespec)
	@config.merge YAML.load_file(@yaml_filespec)
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error loading config file \"#{@yaml_filespec} - " + e.to_s }
    end
  end
  
  def self.default
    # Note, all paths and extensions are case sensitive 

    # Array of paths to scan for media
    # Note, directories underneath these will be added as genres to
    # each .nfo file.  For example:
    # /media/royw-gentoo/public/data/movies/Action/Bond/Goldeneye.m4v
    # will add 'Action' and 'Bond' genres to Goldeneye.nfo
    # Also note, that duplicate genres will be collapsed into single
    # genres in the .nfo file.
    @config.directories = [
	'/media/dad-kubuntu/public/data/videos_iso',
	'/media/dcerouter/public/data/videos_iso',
	'/media/royw-gentoo/public/data/videos_iso',
	'/media/royw-gentoo/public/data/movies'
      ]

    # Typical locations are:
    # @config.collection_filespec = File.join(ENV['HOME'], 'DVD Profiler/Databases/Exports/Collection.xml')
    # @config.images_dir = File.join(ENV['HOME'], 'DVD Profiler/Databases/Default/Images')
    #
    # My locations are:
    @config.collection_filespec = '/home/royw/DVD Profiler/Shared/Collection.xml'
    @config.images_dir = '/home/royw/DVD Profiler/Shared/Images'

    # You will probably need to edit the MEDIA_EXTENSIONS to specify
    # the containers used in your library
    @config.media_extensions = [ 'iso', 'm4v' ]

    # You probably will not need to change these
    # Source file extensions.
    @config.image_extensions    = [ 'jpg', 'jpeg', 'png', 'gif' ]
    @config.nfo_extensions      = [ 'nfo' ]
    # Destination file extensions
    @config.thumbnail_extension  = 'tbn'
    @config.nfo_extension        = 'nfo'
    @config.nfo_backup_extension = 'nfo~'

    # map some genre names
    @config.genre_maps = {
	'Science-Fiction' => 'Science Fiction',
	'Anime'           => 'Animation',
	'Musical'         => 'Musicals'
      }

    @config.file_permissions = 0664
    @config.dir_permissions = 0777
    @config.imdb_query = true
  end
end

######################################################################
# my extensions to Module. (taken from rake, named changed to not clash
# when rake is used for this rails project.
#
class Module
  # Check for an existing method in the current class before extending.  IF
  # the method already exists, then a warning is printed and the extension is
  # not added.  Otherwise the block is yielded and any definitions in the
  # block will take effect.
  #
  # Usage:
  #
  #   class String
  #     rake_extension("xyz") do
  #       def xyz
  #         ...
  #       end
  #     end
  #   end
  #
  def my_extension(method)
    unless instance_methods.include?(method.to_s) || instance_methods.include?(method.to_sym)
      yield
    end
  end
end # module Module

######################################################################
# User defined methods to be added to String.
#
class String
  my_extension("ext") do
    # Replace the file extension with +newext+.  If there is no extenson on
    # the string, append the new extension to the end.  If the new extension
    # is not given, or is the empty string, remove any existing extension.
    #
    # +ext+ is a user added method for the String class.
    def ext(newext='')
      return self.dup if ['.', '..'].include? self
      if newext != ''
        newext = (newext =~ /^\./) ? newext : ("." + newext)
      end
      dup.sub!(%r(([^/\\])\.[^./\\]*$)) { $1 + newext } || self + newext
    end
  end
end # class String

# == Synopsis
# add a blank? method to all Objects
class Object
  my_extension("blank?") do
    # return asserted if object is nil or empty
    # TODO: not the safest coding, probably should dup before stripping.  Maybe should also compact
    def blank?
      result = nil?
      unless result
	if respond_to? 'empty?'
	  if respond_to? 'strip'
	    result = strip.empty?
	  else
	    result = empty?
	  end
	end
      end
      result
    end
  end
end

# == Synopsis
# add an elapse_time_s method to Numeric
class Numeric
  my_extension("elapsed_time_s") do
    # return String formated as "HH:MM:SS"
    def elapsed_time_s
      seconds = self
      hours = minutes = 0
      hours = seconds.div 3600
      seconds = seconds - (hours * 3600)
      minutes = seconds.div 60
      seconds = seconds - (minutes * 60)
      sprintf("%2.2d:%2.2d:%2.2d", hours, minutes, seconds)
    end
  end
end
  
# == Synopsis
# add a timer method to the Kernel
module Kernel

  my_extension("timer") do
    # == Synopsis
    # a simple elapse time for the give block
    # == Usage
    # elapse_seconds = timer {...}
    def timer
      start_time = Time.now
      yield
      Time.now - start_time
    end
  end
end

class ImdbMovie
  def raw_title
    document.at("h1").innerText
  end
  
  def video_game?
    raw_title =~ /\(VG\)/
  end

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
    aka.compact!
    aka
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

###########################################

# == Synopsis
# Media encapsulates information about a single media file
class Media
  attr_reader :media_path, :nfo_files, :image_files, :year, :media_subdirs
  attr_accessor :isbn
  
  def initialize(directory, media_file)
    @media_subdirs = File.dirname(media_file)
    @media_path = File.expand_path(File.join(directory, media_file))
    Dir.chdir(File.dirname(@media_path))
    @nfo_files = Dir.glob("*.{#{AppConfig[:nfo_extensions].join(',')}}")
    @image_files = Dir.glob("*.{#{AppConfig[:media_extensions].join(',')}}")
    @year = $1 if File.basename(@media_path, ".*") =~ /\s\-\s(\d{4})/
  end

  # return the media's title extracted from the filename and cleaned up
  def title
    if @title.nil?
      @title = File.basename(@media_path, ".*")
      @title.gsub!(/\s\-\s\d{4}/, '')  # remove year
      @title.gsub!(/\s\-\s0/, '')      # remove "- 0", i.e., bad year
      @title.gsub!(/\(\d{4}\)/, '')    # remove (year)
      @title.gsub!(/\[.+\]/, '')       # remove square brackets
      @title.gsub!(/\s\s+/, ' ')       # remove multiple whitespace
      @title = @title.strip            # remove leading and trailing whitespace
    end
    @title
  end
  
  # return the media's title but with the (year) appended
  def title_with_year
    name = title
    name = "#{name} (#{@year})" unless @year.nil?
    name
  end
  
  def to_s
    buf = []
    buf << @media_path
    buf << '-'
    buf << title_with_year
    buf.join(' ')
  end
end

# == Synopsis
# encapsulation of all media files
class MediaFiles
  attr_reader :medias, :titles

  # given:
  # directories Array of String directory pathspecs
  def initialize(directories)
    @medias = []
    directories.each do |dir|
      Dir.chdir(dir)
      @medias += Dir.glob("**/*.{#{AppConfig[:media_extensions].join(',')}}").collect do |filename| 
	Media.new(dir, filename)
      end
    end
    @titles = {}
    @medias.each do |media|
      title = media.title_with_year
      @titles[title] ||= []
      @titles[title] << media
    end
  end
  
  
  # find duplicate titles and return them in a hash
  # where the key is the title and the value is an
  # array of Media objects
  def duplicate_titles
    duplicates = {}
    @titles.each do |title, medias|
      if medias.length > 1
	duplicates[title] = medias
      end
    end
    duplicates
  end
end

# == Synopsis
# NFO (info) files
class NFO
  def initialize(media, dvd_hash)
    @media = media
    @dvd_hash = dvd_hash
    load
  end
  
  # save as a .nfo file, creating a backup if the .nfo already exists
  def save
    begin
      nfo_filespec = @media.media_path.ext(".#{AppConfig[:nfo_extension]}")
      nfo_backup_filespec = @media.media_path.ext(".#{AppConfig[:nfo_backup_extension]}")
      File.delete(nfo_backup_filespec) if File.exist?(nfo_backup_filespec)
      File.rename(nfo_filespec, nfo_backup_filespec) if File.exist?(nfo_filespec)
      File.open(nfo_filespec, "w") do |file|
	file.puts(to_nfo(@dvd_hash))
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error saving nfo file - " + e.to_s }
    end
  end
  
  def load
    begin
      nfo_filespec = @media.media_path.ext(".#{AppConfig[:nfo_extension]}")
      @movie = XmlSimple.xml_in(nfo_filespec) if File.exist? nfo_filespec
    rescue Exception => e
      AppConfig[:logger].error { "Error loading \"#{nfo_filespec}\" - " + e.to_s }
    end
  end
  
  # return a nfo xml String from the given dvd_hash (from Collection)
  def to_nfo(dvd_hash)
    @movie ||= {}
    imdb_id = @movie['id']
    imdb_id = imdb_lookup(dvd_hash) if AppConfig[:imdb_query] && imdb_id.blank?
    @movie['title']         = dvd_hash[:title]
    @movie['mpaa']          = dvd_hash[:rating]
    @movie['year']          = dvd_hash[:productionyear]
    @movie['outline']       = dvd_hash[:overview]
#     @movie['plot']          = dvd_hash[:overview]
    @movie['runtime']       = dvd_hash[:runningtime]
    @movie['genre']         = map_genres((dvd_hash[:genres] + @media.media_subdirs.split('/')).uniq)
    @movie['actor']         = dvd_hash[:actors]
    @movie['id']            = imdb_id unless imdb_id.nil?
    @movie['isbn']          = dvd_hash[:isbn]
  
    begin
      XmlSimple.xml_out(@movie, 'NoAttr' => true, 'RootName' => 'movie')
    rescue Exception => e
      AppConfig[:logger].error { "Error creating nfo file - " + e.to_s }
    end
  end
  
  protected
  
  def map_genres(genres)
    new_genres = []
    genres.each do |genre|
      new_genres << (AppConfig[:genre_maps][genre].nil? ? genre : AppConfig[:genre_maps][genre])
    end
    new_genres.uniq.compact
  end

  # try to find the imdb id for the movie
  def imdb_lookup(dvd_hash)
    id = nil
    AppConfig[:logger].info { "Searching IMDB for \"#{dvd_hash[:title]}\"" }
    unless dvd_hash[:title].blank?
      years = released_years(dvd_hash)
      begin
	imdb_search = ImdbSearch.new(dvd_hash[:title])
	id = imdb_search.find_id(:years => years, :media_path => @media.media_path)
      rescue Exception => e
	AppConfig[:logger].error { "Error searching IMDB - " + e.to_s }
	AppConfig[:logger].error { e.backtrace.join("\n") }
      end
    end
    AppConfig[:logger].info { "IMDB id => #{id}" } unless id.nil?
    id
  end

  # Different databases seem to mix up released versus production years.
  # So we combine both into a Array of integer years.
  def released_years(dvd_hash)
    years = []
    unless dvd_hash[:productionyear].blank?
      years += dvd_hash[:productionyear].collect{|y| [y.to_i - 1, y.to_i, y.to_i + 1]}.flatten
    end
    unless dvd_hash[:released].blank?
      years += dvd_hash[:released].collect do |date|
	y = nil
	y = $1.to_i if date =~ /(\d{4})\-/
	y
      end
    end
    years.flatten.uniq.compact.sort
  end
  
end

# == Synopsis
# This model encapsulates the DVDProfiler Collection.xml
class Collection
  # various regexes used to clean up a title for matching purposes.
  # used in TITLE_REPLACEMENTS hash below
  PUNCTUATION = /[\?\:\!\"\'\,\.\-\/]/
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
    @title_isbn_hash = {}
    @isbn_dvd_hash = {}
    @isbn_title_hash = {}
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
    collection = {}
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
          dvd_hash = {}
          dvd_hash[:isbn] = isbn
          dvd_hash[:title] = original_title
          unless dvd[:actors].blank?
            dvd_hash[:actors] = dvd[:actors].compact.collect {|a| a[:actor]}.flatten.compact.collect do |a|
              name = []
              name << a['FirstName'] unless a['FirstName'].blank?
              name << a['MiddleName'] unless a['MiddleName'].blank?
              name << a['LastName'] unless a['LastName'].blank?
	      info = {}
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
          @isbn_dvd_hash[isbn] = dvd_hash
        end
      end
    end
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

# == Synopsis
# Transfer media meta data from DvdProfiler to the format that XBMC needs it (.tbn and .nfo files)
#
# usage:
#  app = DvdProfiler2Xbmc.new
#  app.execute
#  app.report.each {|line| puts line}
class DvdProfiler2Xbmc
  @interrupted = false

  # A trap("INT") in the Runner calls this to indicate that a ^C has been detected.
  # Note, once set, it is never cleared
  def self.interrupt
    AppConfig[:logger].error { "control-C detected, finishing current task" }
    @interrupted = true
  end

  # Long loops should poll this method to see if they should abort
  # Returns:: true if the application has trapped an "INT", false otherwise
  def self.interrupted?
    @interrupted
  end

  def initialize
    @media_files = nil
    @collection = nil
  end
  
  def execute
    @media_files = MediaFiles.new(AppConfig[:directories])
    
    collection_filepath = File.expand_path(AppConfig[:collection_filespec])
    @collection = Collection.new(collection_filepath)

    @media_files.titles.each do |title, medias|
      break if DvdProfiler2Xbmc.interrupted?
      # the following lines are order dependent
      find_isbns(title, medias)
      copy_thumbnails(title, medias)
      create_nfos(title, medias)
#       set_file_permissions(title, medias)
    end
    
    AppConfig[:directories].each do |dir|
      Dir.glob(File.join(dir, '**/*')).each do |f|
	if File.directory?(f)
	  File.chmod(AppConfig[:dir_permissions], f) 
	else
	  File.chmod(AppConfig[:file_permissions], f) 
	end
      end
    end
  end

  # generate the report.
  # Note, must be ran after execute()
  # returns an array of lines
  def report
    buf = []
    unless DvdProfiler2Xbmc.interrupted?
      unless @media_files.nil?
	duplicates = duplicates_report
	unless duplicates.empty?
	  buf << "Duplicates:\n" 
	  buf += duplicates
	end
	
	missing_isbns = missing_isbn_report
	unless missing_isbns.empty?
	  buf += missing_isbns
	end
      end
    end
    buf
  end
  
  protected
  
  # find ISBN for each title and assign to the media
  def find_isbns(title, medias)
    title_pattern = Collection.title_pattern(title)
    unless @collection.title_isbn_hash[title_pattern].nil?
      medias.each do |media|
	media.isbn = @collection.title_isbn_hash[title_pattern]
      end
    end
  end

  # copy images from .../isbn.jpg to .../basename.jpg
  def copy_thumbnails(title, medias)
    medias.each do |media|
      unless media.isbn.nil?
	media.isbn.each do |isbn|
	  src_image_filespec = File.join(AppConfig[:images_dir], "#{isbn}f.jpg")
	  if File.exist?(src_image_filespec)
	    dest_image_filespec = media.media_path.ext(".#{AppConfig[:thumbnail_extension]}")
	    File.copy(src_image_filespec, dest_image_filespec)
	  end
	end
      end
    end
  end

  # create nfo files from collection.isbn_dvd_hash
  def create_nfos(title, medias)
    medias.each do |media|
      unless media.isbn.nil?
	media.isbn.each do |isbn|
	  dvd_hash = @collection.isbn_dvd_hash[isbn]
	  unless dvd_hash.nil?
	    nfo = NFO.new(media, dvd_hash)
	    nfo.save
	  end
	end
      end
    end
  end

#   # set the file permissions for the media files
#   def set_file_permissions(title, medias)
#     medias.each do |media|
#       AppConfig[:file_permissions].each do |permissions, extensions|
# 	extensions.each do |extension|
# 	  filespec = media.media_path.ext(".#{extension}")
# 	  File.chmod(permissions.to_i, filespec) if File.exist?(filespec)
# 	end
#       end
#     end
#   end
  
  # duplicate media file report
  def duplicates_report
    buf = []
    duplicates = @media_files.duplicate_titles
    unless duplicates.empty?
      duplicates.each do |title, medias|
	if medias.length > 1
	  buf << title
	  medias.each {|media| buf << "  #{media.media_path}"}
	end
      end
    end
    buf
  end
  
  # unable to find ISBN for these titles report
  def missing_isbn_report
    buf = []
    @media_files.titles.each do |title, medias|
      if medias.nil?
	buf << "No media for #{title}"
      else
	if medias[0].isbn.nil?
	  buf << "ISBN not found for #{title}"
	  medias.each {|media| buf << "  #{media.media_path}"}
	end
      end
    end
    buf
  end

end

# Command line interface
if __FILE__ == $0
  
    # == Synopsis
  # The Runner module encapsulates the command line application
  module Runner

    # == Synopsis
    # Command line exit codes
    class ExitCode
      UNKNOWN = 3
      CRITICAL = 2
      WARNING = 1
      OK = 0
    end
  
    # Run the command-line application
    # args:: the command-line argument Array
    # Returns:: ExitCode value
    def self.run(args)
      exit_code = ExitCode::OK
      
      # we start a STDOUT logger, but it will be switched after 
      # the config files are read if config[:logger_output] is set
      logger = Log4r::Logger.new('dvdprofiler2xbmc')
      logger.outputters = Log4r::StdoutOutputter.new(:console)
      logger.level = Log4r::DEBUG
      
      begin
	# trap ^C interrupts and let the app instance cleanly exit any long loops
	Signal.trap("INT") {DvdProfiler2Xbmc.interrupt}

        
        # parse the command line
        options = setupParser()
        od = options.parse(args)

	unless od["--help"]
	  # load config values
	  AppConfig.default
	  AppConfig[:pretend] = od["--pretend"]
	  AppConfig[:imdb_query] = !od["--no_imdb_query"]
	  
	  # the first reinitialize_logger adds the command line logging options to the default config
	  # then we load the config files
	  # then we run reinitialize_logger again to modify the logger for any logging options from the config files
	  
	  reinitialize_logger(logger, od["--verbose"], od["--debug"])
	  AppConfig.load
	  reinitialize_logger(logger, od["--verbose"], od["--debug"])
	  
	  # create and execute class instance here
	  app = DvdProfiler2Xbmc.new
	  app.execute
	  app.report.each {|line| puts line}
	end
      rescue Exception => eMsg
        logger.error {eMsg.to_s}
        logger.error {options.to_s}
        logger.error {eMsg.backtrace.join("\n")}
        exit_code = ExitCode::CRITICAL
      end
      exit_code
    end

  
    # Setup the command line option parser
    # Returns:: OptionParser instances
    def self.setupParser()
      options = OptionParser.new()
      options << Option.new(:flag, :names => %w(--help), 
                            :opt_found => lambda {Log4r::Logger['dvdprofiler2xbmc'].info{options.to_s}}, 
                            :opt_description => "This usage information")
      options << Option.new(:flag, :names => %w(--pretend -p))
      options << Option.new(:flag, :names => %w(--no_imdb_query -n))
      options << Option.new(:flag, :names => %w(--verbose -v))
      options << Option.new(:flag, :names => %w(--debug -d))
      options
    end
    
    # Reinitialize the logger using the loaded config.
    # logger:: logger for any user messages
    # config:: is the application's config hash.
    def self.reinitialize_logger(logger, verbose, debug)
      # switch the logger to the one specified in the config files
      unless AppConfig[:logfile].nil?
        logfile_outputter = Log4r::RollingFileOutputter.new(:logfile, :filename => AppConfig[:logfile], :maxsize => 1000000 )
        logger.add logfile_outputter
        logfile_outputter.level = Log4r::INFO
        Log4r::Outputter[:logfile].formatter = Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %M")
        unless AppConfig[:logfile_level].nil?
          level_map = {'DEBUG' => Log4r::DEBUG, 'INFO' => Log4r::INFO, 'WARN' => Log4r::WARN}
          logfile_outputter.level = level_map[AppConfig[:logfile_level]] || Log4r::INFO
        end
      end
      Log4r::Outputter[:console].level = Log4r::WARN
      Log4r::Outputter[:console].level = Log4r::INFO if verbose
      Log4r::Outputter[:console].level = Log4r::DEBUG if debug
      # logger.trace = true
      AppConfig[:logger] = logger
    end
  end
  
  exit Runner.run(ARGV)
end

    