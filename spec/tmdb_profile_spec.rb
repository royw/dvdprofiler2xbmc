require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

# Time to add your specs!
# http://rspec.info/

describe "TmdbProfile" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::INFO
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    File.mkdirs(TMPDIR)
  end

  before(:each) do
    @profile = TmdbProfile.first(:imdb_id => 'tt0465234')
  end

  after(:all) do
    Dir.glob(File.join(TMPDIR,'tmdb_profile_spec*')).each { |filename| File.delete(filename) }
  end

  it "should find by imdb_id" do
    @profile.should_not == nil
  end

  it "should save the .tmdb.xml file" do
    outfile = Tempfile.new('tmdb_movie_spec_saving', TMPDIR)
    profile = TmdbProfile.first(:imdb_id => 'tt0465234')
    unless profile.nil?
      profile.save(outfile.path)
    end
    (File.exist?(outfile.path).should be_true) && (File.size(outfile.path).should > 0)
  end

  it "should be able to convert to xml" do
    xml = @profile.to_xml
    (xml.should_not be_nil) && (xml.length.should > 0)
  end

  it "should be able to convert to xml and then from xml" do
    hash = nil
    begin
      xml = @profile.to_xml
      hash = XmlSimple.xml_in(xml)
    rescue
      hash = nil
    end
    hash.should_not be_nil
  end

  it "should find tmdb id" do
    @profile.movie['idents'].first.should == '6637'
  end

  it "should find fanarts" do
    @profile.movie['fanarts'].size.should == 3
  end

  it "should find posters" do
    @profile.movie['posters'].size.should == 4
  end

  it "should find the tmdb url" do
    @profile.movie['urls'].first.should == 'http://www.themoviedb.org/movie/6637'
  end

  it "should find the imdb_id" do
    @profile.movie['imdb_ids'].first.should == 'tt0465234'
  end

  it "should find the title" do
    @profile.movie['titles'].first.should == 'National Treasure: Book of Secrets'
  end

  it "should find the short_overview" do
    @profile.movie['short_overviews'].first.should =~ /Benjamin Franklin Gates/
  end

  it "should find the type" do
    @profile.movie['types'].first.should == 'movie'
  end

  it "should find the alternative_titles" do
    @profile.movie['alternative_titles'].first.should == 'National Treasure 2'
  end

  it "should find the release" do
    @profile.movie['releases'].first.should == '2007-12-13'
  end

  it "should find the  score" do
    @profile.movie['scores'].first.should == '1.0'
  end

end

