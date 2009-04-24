require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

describe "App" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::WARN
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    File.mkdirs(TMPDIR)
  end

  after(:all) do
    Dir.glob(File.join(TMPDIR, "app_*")).each do |filename|
      File.delete(filename) if File.file?(filename)
      Dir.rmdir(filename) if File.directory?(filename)
    end
  end

  it 'should save a file' do
    # get a temp filename to a non-existing file
    outfile = Tempfile.new('app_spec', TMPDIR)
    filespec = outfile.path
    outfile.unlink

    data = 'Howdy Partner'

    DvdProfiler2Xbmc.save_to_file(filespec, data)
    open(filespec).read.should == "#{data}\n"
  end

  it 'should backup the file before saving' do
    # get a temp filename to a non-existing file
    outfile = Tempfile.new('app_spec', TMPDIR)
    filespec = outfile.path
    backupspec = filespec + AppConfig[:extensions][:backup]
    outfile.unlink

    data = []
    data[0] = 'Howdy Partner'
    data[1] = 'Howdy Ho Neighbor'

    DvdProfiler2Xbmc.save_to_file(filespec, data[0])
    DvdProfiler2Xbmc.save_to_file(filespec, data[1])
    open(filespec).read.should == "#{data[1]}\n" &&
    open(backupspec).read.should == "#{data[0]}\n"
  end

  it 'should generate .nfo filespec for single part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.m4v', :nfo)
    filespec.should == '/a/b/c.nfo'
  end

  it 'should generate .nfo filespec for multiple part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.cd1.m4v', :nfo)
    filespec.should == '/a/b/c.nfo'
  end

  it 'should generate .tbn filespec for single part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.m4v', :thumbnail)
    filespec.should == '/a/b/c.tbn'
  end

  it 'should generate .tbn filespec for multiple part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.cd1.m4v', :thumbnail)
    filespec.should == '/a/b/c.tbn'
  end

  it 'should generate -fanart filespec for single part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.m4v', :fanart)
    filespec.should == '/a/b/c-fanart'
  end

  it 'should generate -fanart filespec for multiple part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.cd1.m4v', :fanart)
    filespec.should == '/a/b/c-fanart'
  end

  it 'should generate -fanart.jpg filespec for single part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.m4v', :fanart, :extension => File.extname('foo.jpg'))
    filespec.should == '/a/b/c-fanart.jpg'
  end

  it 'should generate -fanart.jpg filespec for multiple part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.cd1.m4v', :fanart, :extension => File.extname('foo.jpg'))
    filespec.should == '/a/b/c-fanart.jpg'
  end

  it 'should generate .imdb.xml filespec for single part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.m4v', :imdb_xml)
    filespec.should == '/a/b/c.imdb.xml'
  end

  it 'should generate .imdb.xml filespec for multiple part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.cd1.m4v', :imdb_xml)
    filespec.should == '/a/b/c.imdb.xml'
  end

  it 'should generate .tmdb.xml filespec for single part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.m4v', :tmdb_xml)
    filespec.should == '/a/b/c.tmdb.xml'
  end

  it 'should generate .tmdb.xml filespec for multiple part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.cd1.m4v', :tmdb_xml)
    filespec.should == '/a/b/c.tmdb.xml'
  end

  it 'should generate .dvdprofiler.xml filespec for single part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.m4v', :dvdprofiler_xml)
    filespec.should == '/a/b/c.dvdprofiler.xml'
  end

  it 'should generate .dvdprofiler.xml filespec for multiple part media' do
    filespec = DvdProfiler2Xbmc.generate_filespec('/a/b/c.cd1.m4v', :dvdprofiler_xml)
    filespec.should == '/a/b/c.dvdprofiler.xml'
  end

  it 'should change file permissions' do
    outfile = Tempfile.new('app_permission_check', TMPDIR)
    filespec = outfile.path
    File.chmod(0777, filespec)
    AppConfig.config[:file_permissions] = 0642.to_s(8)
    # set_permissions is protected method
    DvdProfiler2Xbmc.instance.send('set_permissions', TMPDIR)
    (File.stat(filespec).mode & 07777).should == 0642
  end

  it 'should change directory permissions' do
    outdir = Tempfile.new('app_permission_check', TMPDIR)
    dirspec = outdir.path
    outdir.unlink
    Dir.mkdir(dirspec)
    File.chmod(0777, dirspec)
    AppConfig.config[:dir_permissions] = 0642.to_s(8)
    # set_permissions is protected method
    DvdProfiler2Xbmc.instance.send('set_permissions', TMPDIR)
    (File.stat(dirspec).mode & 07777).should == 0642
  end
end
