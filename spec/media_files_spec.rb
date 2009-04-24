require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

describe "MediaFiles" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::WARN
    AppConfig.default
    AppConfig[:logger] = logger
#     AppConfig.load
    File.mkdirs(TMPDIR)
    @titles = [
        'Alexander the Great',
        'Anastasia',
        'About a Boy',
        'Gung Ho',
        'Hot Shots',
        'Meltdown',
        'Oklahoma!',
        'The Man From Snowy River',
        'Rooster Cogburn (...and the Lady)',
        'Call Me The Rise And Fall of Heidi Fleiss',
        'batteries not included',
        'Flyboys',
        "Captain Corelli's Mandolin",
      ]
  end

  after(:each) do
    dup_dir = File.join(TMPDIR, 'dups')
    if File.exist?(dup_dir)
      Dir.glob(File.join(dup_dir, "*.m4v")).each { |filename| File.delete(filename) }
      Dir.delete(dup_dir)
    end
    Dir.glob(File.join(TMPDIR, "*.m4v")).each { |filename| File.delete(filename) }
  end

  describe "Finders" do
    it "should find the correct number of titles using relative directory paths" do
      @titles.each {|title| File.touch(File.join(TMPDIR, "#{title}.m4v"))}
      media_files = MediaFiles.new([TMPDIR])
      media_files.titles.length.should == @titles.length
    end

    it "should find the correct number of titles using absolute directory paths" do
      @titles.each {|title| File.touch(File.join(TMPDIR, "#{title}.m4v"))}
      media_files = MediaFiles.new([File.expand_path(TMPDIR)])
      media_files.titles.length.should == @titles.length
    end

    it "should find the correct number of media files using relative directory paths" do
      @titles.each {|title| File.touch(File.join(TMPDIR, "#{title}.m4v"))}
      media_files = MediaFiles.new([TMPDIR])
      media_files.medias.length.should == @titles.length
    end

    it "should find the correct number of media files using absolute directory paths" do
      @titles.each {|title| File.touch(File.join(TMPDIR, "#{title}.m4v"))}
      media_files = MediaFiles.new([File.expand_path(TMPDIR)])
      media_files.medias.length.should == @titles.length
    end

    it "should find all of the titles according to the titles hash" do
      @titles.each {|title| File.touch(File.join(TMPDIR, "#{title}.m4v"))}
      media_files = MediaFiles.new([TMPDIR])
      (media_files.titles.keys.sort - @titles.sort).empty?.should be_true
    end

    it "should find all of the media files according to the medias array" do
      @titles.each {|title| File.touch(File.join(TMPDIR, "#{title}.m4v"))}
      media_files = MediaFiles.new([TMPDIR])
      (media_files.medias.collect{|media| media.title}.sort - @titles.sort).empty?.should be_true
    end
  end

  describe "Duplicates" do
    it "should not find any duplicate titles when there are none" do
      @titles.each {|title| File.touch(File.join(TMPDIR, "#{title}.m4v"))}
      media_files = MediaFiles.new([File.expand_path(TMPDIR)])
      media_files.duplicate_titles.length.should == 0
    end

    # nfo_controller.execute has not been ran, so the only information
    # in each media instance is what was gathered from the filename.
    # So this means filenames with years will not match against identical
    # titles but without years.
    # So the only way we can test is against identical filenames in multiple
    # directories.
    it "should find duplicate titles when there are some" do
      @titles.each {|title| File.touch(File.join(TMPDIR, "#{title}.m4v"))}
      File.mkdirs(File.join(TMPDIR, 'dups'))
      duplicate_titles = @titles[0..(@titles.length/3)]
      duplicate_titles.each {|title| File.touch(File.join(TMPDIR, 'dups', "#{title}.m4v"))}
      media_files = MediaFiles.new([File.expand_path(TMPDIR)])
      media_files.duplicate_titles.length.should == duplicate_titles.length
    end
  end

end
