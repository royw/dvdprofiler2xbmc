require File.dirname(__FILE__) + '/spec_helper.rb'
require File.join(File.dirname(__FILE__), '../lib/dvdprofiler2xbmc/views/config_editor')

require 'tempfile'

describe "ConfigEditor" do

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

  before(:each) do
    @input    = StringIO.new
    @output   = StringIO.new
    @old_terminal = $terminal
    $terminal = HighLine.new(@input, @output)
    @editor = ConfigEditor.new
  end

  after(:each) do
    $terminal = @old_terminal
  end

  it "should return true for boolean data type edits that recieve y" do
    @input << "y\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'field_name', :BOOLEAN, false)
    value.should be_true
  end

  it "should return false for boolean data type edits that recieve n" do
    @input << "n\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'field_name', :BOOLEAN, true)
    value.should be_false
  end

  it "should return true for boolean data type edits that recieve yes" do
    @input << "yes\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'field_name', :BOOLEAN, false)
    value.should be_true
  end

  it "should return false for boolean data type edits that recieve no" do
    @input << "no\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'field_name', :BOOLEAN, true)
    value.should be_false
  end

  it "should return false for boolean data type edits that default to false" do
    @input << "\n\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'field_name', :BOOLEAN, false)
    value.should be_false
  end

  it "should return true for boolean data type edits that default to true" do
    @input << "\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'field_name', :BOOLEAN, true)
    value.should be_true
  end

  it "should handle ask commands" do
    pathspec = File.expand_path(__FILE__)
    @input << pathspec << "\n"
    @input.rewind
    value = ask('New filespec: ')
    value.should == pathspec
  end

  it "should handle ask commands with validation" do
    pathspec = File.expand_path(__FILE__)
    @input << pathspec << "\n"
    @input.rewind
    value = ask('New filespec: ') do |q|
      q.validate = lambda { |p| File.exist?(p) && File.file?(p) }
      q.confirm = false
    end
    value.should == pathspec
  end

  it "should return pathspec" do
    pathspec = File.expand_path(File.dirname(__FILE__))
    default_pathspec = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    @input << pathspec << "\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'images_dir', :PATHSPEC, default_pathspec)
    value.should == pathspec
  end

  it "should return default pathspec" do
    default_pathspec = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    @input << "\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'images_dir', :PATHSPEC, default_pathspec)
    value.should == default_pathspec
  end

  it "should reprompt for invalid pathspec" do
    badpathspec = '/a123/b123/c123'
    goodpathspec = File.expand_path(File.dirname(__FILE__))
    default_pathspec = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    @input << badpathspec << "\n" << goodpathspec << "\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'images_dir', :PATHSPEC, default_pathspec)
    value.should == goodpathspec
  end

  it "should return filespec data type edits" do
    filespec = File.expand_path(__FILE__)
    default_filespec = File.expand_path(File.join(File.dirname(__FILE__), 'ruby_dragon'))
    @input << filespec << "\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'collection_filespec', :FILESPEC, default_filespec)
    value.should == filespec
  end

  it "should reprompt for invalid filespec" do
    badfilespec = File.expand_path(__FILE__) + 'jaberwooky'
    goodfilespec = File.expand_path(__FILE__)
    default_filespec = File.expand_path(File.join(File.dirname(__FILE__), 'ruby_dragon'))
    @input << badfilespec << "\n" << goodfilespec << "\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'collection_filespec', :FILESPEC, default_filespec)
    value.should == goodfilespec
  end

  it "should accept valid permission 0" do
    @input << "0" << "\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'file_permissions', :PERMISSIONS, 0644.to_s(8))
    value.should == 0.to_s(8)
  end

  it "should accept valid permission 7777" do
    @input << "7777" << "\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'file_permissions', :PERMISSIONS, 0644.to_s(8))
    value.should == 07777.to_s(8)
  end

  it "should reject permission > 7777" do
    @input << "65432" << "\n" << "6543" << "\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'file_permissions', :PERMISSIONS, 0644.to_s(8))
    value.should == 06543.to_s(8)
  end

  it "should accept array of strings" do
    strings = %w(foo bar howdy)
    @input << strings.join("\n") << "\n\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'image_extensions', :ARRAY_OF_STRINGS)
    value.should == strings
  end

  it "should accept empty array of strings" do
    strings = []
    @input << strings.join("\n") << "\n\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'image_extensions', :ARRAY_OF_STRINGS)
    value.should == strings
  end

  it "should accept array of pathspecs" do
    cwd = File.expand_path(File.dirname(__FILE__))
    pathspecs = [cwd, File.join(cwd, '..')]
    @input << pathspecs.join("\n") << "\n\n\n\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'directories', :ARRAY_OF_PATHSPECS)
    value.should == pathspecs
  end

  it "should accept empty array of pathspecs" do
    pathspecs = []
    @input << pathspecs.join("\n") << "\n\n\n"
    @input.rewind
    value = @editor.send('data_type_editor', 'directories', :ARRAY_OF_PATHSPECS)
    value.should == pathspecs
  end

  it "should reject empty directories" do
    AppConfig.config['directories'] = []
    AppConfig.validate['directories'].call([]).should be_false
  end

  it 'should indicate valid AppConfig' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, File.join(cwd, '..')]
    AppConfig.config.collection_filespec = __FILE__
    AppConfig.config.images_dir = cwd
    AppConfig.valid?.should be_true
  end

  it 'should indicate invalid AppConfig with no directories' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = []
    AppConfig.config.collection_filespec = __FILE__
    AppConfig.config.images_dir = cwd
    AppConfig.valid?.should be_false
  end

  it 'should indicate invalid AppConfig with bad directory path' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, cwd + 'jaberwooky']
    AppConfig.config.collection_filespec = __FILE__
    AppConfig.config.images_dir = cwd
    AppConfig.valid?.should be_false
  end

  it 'should indicate invalid AppConfig with empty collection.xml path' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, File.join(cwd, '..')]
    AppConfig.config.collection_filespec = ''
    AppConfig.config.images_dir = cwd
    AppConfig.valid?.should be_false
  end

  it 'should indicate invalid AppConfig with bad collection.xml path' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, File.join(cwd, '..')]
    AppConfig.config.collection_filespec = cwd + 'jaberwooky'
    AppConfig.config.images_dir = cwd
    AppConfig.valid?.should be_false
  end

  it 'should indicate invalid AppConfig with empty images path' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, File.join(cwd, '..')]
    AppConfig.config.collection_filespec = __FILE__
    AppConfig.config.images_dir = ''
    AppConfig.valid?.should be_false
  end

  it 'should indicate invalid AppConfig with bad images path' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, File.join(cwd, '..')]
    AppConfig.config.collection_filespec = __FILE__
    AppConfig.config.images_dir = cwd + 'jaberwooky'
    AppConfig.valid?.should be_false
  end

  it 'should indicate invalid AppConfig with no media extensions' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, File.join(cwd, '..')]
    AppConfig.config.collection_filespec = __FILE__
    AppConfig.config.images_dir = cwd
    AppConfig.config.media_extensions = []
    AppConfig.valid?.should be_false
  end

  it 'should indicate invalid AppConfig with no image extensions' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, File.join(cwd, '..')]
    AppConfig.config.collection_filespec = __FILE__
    AppConfig.config.images_dir = cwd
    AppConfig.config.image_extensions = []
    AppConfig.valid?.should be_false
  end

  it 'should indicate invalid AppConfig with invalid file permissions' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, File.join(cwd, '..')]
    AppConfig.config.collection_filespec = __FILE__
    AppConfig.config.images_dir = cwd
    AppConfig.config.file_permissions = '-2'
    AppConfig.valid?.should be_false
  end

  it 'should indicate invalid AppConfig with invalid directory permissions' do
    cwd = File.expand_path(File.dirname(__FILE__))
    AppConfig.default
    AppConfig.config.directories = [cwd, File.join(cwd, '..')]
    AppConfig.config.collection_filespec = __FILE__
    AppConfig.config.images_dir = cwd
    AppConfig.config.dir_permissions = '11111'
    AppConfig.valid?.should be_false
  end

end
