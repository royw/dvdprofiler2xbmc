# %w[rubygems rake rake/clean fileutils newgem rubigen].each { |f| require f }
#require File.dirname(__FILE__) + '/lib/dvdprofiler2xbmc'
require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "dvdprofiler2xbmc"
    gem.summary = %Q{TODO}
    gem.email = "roy@wright.org"
    gem.homepage = "http://github.com/royw/dvdprofiler2xbmc"
    gem.authors = ["Roy Wright"]

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.add_dependency('activesupport','>= 2.0.2')
    gem.add_dependency('xml-simple','>= 1.0.12')
    gem.add_dependency('royw-read_page_cache','>= 0.0.1')
    gem.add_dependency('royw-imdb','>= 0.1.2')
    gem.add_dependency('royw-tmdb','>= 0.1.5')
    gem.add_dependency('royw-dvdprofiler_collection','>= 0.1.2')
    gem.add_dependency('log4r','>= 1.0.5')
    gem.add_dependency('commandline','>= 0.7.10')
    gem.add_dependency('mash','>= 0.0.3')
    gem.add_dependency('highline', '>= 1.5.0')

    gem.files.reject! do |fn|
      result = false
      basename = File.basename(fn)
      result = true if basename =~ /^tt\d+\.html/
      result = true if basename =~ /^Collection.yaml/
      result
    end
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
  rdoc.title = "dvdprofiler2xbmc #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "stalk github until gem is published"
task :stalk do
  `gemstalk royw dvdprofiler2xbmc`
end



