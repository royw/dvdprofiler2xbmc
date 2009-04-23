require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

# Time to add your specs!
# http://rspec.info/

describe "NfoController" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::WARN

    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load

    DvdprofilerProfile.collection_filespec = File.join(SAMPLES_DIR, 'Collection.xml')
    File.mkdirs(TMPDIR)

    AppConfig[:logger].warn { "\nNfoController Specs" }
  end

  before(:each) do
    @media = Media.new(SAMPLES_DIR, 'The Egg and I.dummy')
    [:imdb_xml, :tmdb_xml, :nfo].each do |extension|
      filespec = @media.path_to(extension)
      File.delete(filespec) if File.exist?(filespec)
    end
#     AppConfig[:logger].info { "media path => " + @media.media_path }
  end

  after(:each) do
    Dir.glob(File.join(TMPDIR, "nfo_controller_spec*")).each { |filename| File.delete(filename) }
    Dir.glob(File.join(TMPDIR, "*.m4v")).each { |filename| File.delete(filename) }
    Dir.glob(File.join(TMPDIR, "*.nfo")).each { |filename| File.delete(filename) }
    Dir.glob(File.join(TMPDIR, "*.xml")).each { |filename| File.delete(filename) }
    Dir.glob(File.join(TMPDIR, "*.dummy")).each { |filename| File.delete(filename) }
    [:imdb_xml, :tmdb_xml, :nfo].each do |extension|
      filespec = File.join(File.dirname(__FILE__), "samples/The Egg and I.#{AppConfig[:extensions][extension]}")
      File.delete(filespec) if File.exist?(filespec)
    end
  end


  it "should use certifications if mpaa not available" do
    NfoController.update(@media)
    filespec = @media.path_to(:nfo)
    xml = open(filespec).read
    hash = XmlSimple.xml_in(xml)
    hash['mpaa'].should == ['Approved']
  end

  it "should update" do
    NfoController.update(@media).should be_true
  end

  it "should generate populated nfo file on update" do
    NfoController.update(@media)
    filespec = @media.path_to(:nfo)
    xml = open(filespec).read
    hash = XmlSimple.xml_in(xml)
    hash['runtime'].should == ['108 min']
  end

  it "should generate populated imdb.xml file on update" do
    NfoController.update(@media)
    filespec = @media.path_to(:imdb_xml)
    xml = open(filespec).read
    hash = XmlSimple.xml_in(xml)
    hash['length'].should == ['108 min']
  end

  it "should generate populated tmdb.xml file on update" do
    NfoController.update(@media)
    filespec = @media.path_to(:tmdb_xml)
    xml = open(filespec).read
    hash = XmlSimple.xml_in(xml)
    hash.should be_empty
  end

  it "should handle different movies with the same title" do
    FileUtils.touch(File.join(TMPDIR, 'Sabrina - 1954.dummy'))
    media1 = Media.new(TMPDIR, 'Sabrina - 1954.dummy')
    controller1 = NfoController.new(media1)
    controller1.update
    FileUtils.touch(File.join(TMPDIR, 'Sabrina - 1995.dummy'))
    media2 = Media.new(TMPDIR, 'Sabrina - 1995.dummy')
    controller2 = NfoController.new(media2)
    controller2.update
    controller1.imdb_id.should_not == controller2.imdb_id
  end

  it "should handle all movies in Collection.xml" do
    imdb_exceptions = [
      'Pearl Harbor Payback Appointment in Tokyo',
      'Rodeo Racketeers John Wayne Young Duke Series',
      'The Adventures of Indiana Jones The Complete DVD Movie Collection',
      'The Great American Western Volume 6',
      'The Mummy Collector s Set',
      'Mexico Whitetails'
    ]
    profiles = DvdprofilerProfile.all
    titles = profiles.collect do |profile|
      info = DvdprofilerInfo.new(profile)
      "#{profile.title.remove_punctuation} - #{info.year}"
    end
    buf = []
    titles.sort.each do |title|
      filename = "#{title}.m4v"
      FileUtils.touch(File.join(TMPDIR, filename))
      media = Media.new(TMPDIR, filename)
      controller = NfoController.new(media)
#       debugger if title =~ /Mexico/
      controller.update
      buf << "Missing ISBN for #{title}" if controller.isbn.blank?
      buf << "Missing IMDB ID for #{controller.info['title']}" if controller.imdb_id.blank? && !imdb_exceptions.include?(media.title)
      buf << "Unexpected IMDB ID for #{controller.info['title']}" if !controller.imdb_id.blank? && imdb_exceptions.include?(media.title)
    end
    puts buf.join("\n") unless buf.empty?
    buf.empty?.should be_true
  end

end

