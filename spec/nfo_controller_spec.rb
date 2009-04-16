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

    DvdprofilerProfile.collection_filespec = AppConfig[:collection_filespec]
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

  after(:all) do
    Dir.glob(File.join(TMPDIR, "nfo_controller_spec*")).each { |filename| File.delete(filename) }
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

#   it "should handle different movies with the same title" do
#     media1 = Media.new('Sabrina - 1954')
#     media2 = Media.new('Sabrina - 1995')
#   end

end