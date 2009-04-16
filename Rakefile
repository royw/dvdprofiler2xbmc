# %w[rubygems rake rake/clean fileutils newgem rubigen].each { |f| require f }
#require File.dirname(__FILE__) + '/lib/dvdprofiler2xbmc'
require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "tmdb"
    gem.summary = %Q{TODO}
    gem.email = "roy@wright.org"
    gem.homepage = "http://github.com/royw/tmdb"
    gem.authors = ["Roy Wright"]

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.add_dependency('activesupport','>= 2.0.2')
    gem.add_dependency('xml-simple','>= 1.0.12')
    gem.add_dependency('royw-imdb','>= 0.0.19')
    gem.add_dependency('royw-tmdb','>= 0.0.1')
    gem.add_dependency('log4r','>= 1.0.5')
    gem.add_dependency('commandline','>= 0.7.10')
    gem.add_dependency('mash','>= 0.0.3')
    gem.add_dependency('highline', '>= 1.5.0')

    gem.files.reject! { |fn| File.basename(fn) =~ /^tt\d+\.html/}
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end


task :default => :spec

Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "tmdb #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
#$hoe = Hoe.new('dvdprofiler2xbmc', Dvdprofiler2xbmc::VERSION) do |p|
#  p.developer('Roy Wright', 'roy@wright.org')
#  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
#  p.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
#  p.rubyforge_name       = p.name # TODO this is default value
#  p.extra_deps         = [
#    ['activesupport','>= 2.0.2'],
#    ['xml-simple','>= 1.0.12'],
#    ['royw-imdb','>= 0.0.19'],
#    ['royw-tmdb','>= 0.0.1'],
#    ['log4r','>= 1.0.5'],
#    ['commandline','>= 0.7.10'],
#    ['mash','>= 0.0.3'],
#    ['highline', '>= 1.5.0']
#  ]
#  p.extra_dev_deps = [
#    ['newgem', ">= #{::Newgem::VERSION}"]
#  ]
#
#  p.clean_globs |= %w[**/.DS_Store tmp *.log]
#  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
#  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
#  p.rsync_args = '-av --delete --ignore-errors'
#end

#require 'newgem/tasks' # load /tasks/*.rake
#Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# task :default => [:spec, :features]
