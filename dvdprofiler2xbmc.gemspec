# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dvdprofiler2xbmc}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Roy Wright"]
  s.date = %q{2009-03-20}
  s.default_executable = %q{dvdprofiler2xbmc}
  s.description = %q{This script will attempt to match up media files from a set of directories to the collection.xml file exported from DVD Profiler.  For matches, the script will then create a {moviename}.nfo from the data in collections.xml and also copy the front cover image to {moviename}.tbn.  Both files will be placed in the same directory as the source media file.  Then on XBMC, set the source content to none to remove the meta data from the library, then set the source content back to Movies to import the media.  This time, the data in the .nfo files will be used instead of scraping.}
  s.email = ["roy@wright.org"]
  s.executables = ["dvdprofiler2xbmc"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "bin/dvdprofiler2xbmc", "lib/dvdprofiler2xbmc.rb", "lib/dvdprofiler2xbmc/app_config.rb", "lib/dvdprofiler2xbmc/app.rb", "lib/dvdprofiler2xbmc/cli.rb", "lib/dvdprofiler2xbmc/collection.rb", "lib/dvdprofiler2xbmc/extensions.rb", "lib/dvdprofiler2xbmc/imdb_extensions.rb", "lib/dvdprofiler2xbmc/media_files.rb", "lib/dvdprofiler2xbmc/media.rb", "lib/dvdprofiler2xbmc/nfo.rb", "test/test_dvdprofiler2xbmc.rb", "test/test_helper.rb", "test/test_dvdprofiler2xbmc_cli.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://www.github.com/royw/dvdprofiler2xbmc}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dvdprofiler2xbmc}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{This script will attempt to match up media files from a set of directories to the collection.xml file exported from DVD Profiler}
  s.test_files = ["test/test_dvdprofiler2xbmc.rb", "test/test_helper.rb", "test/test_dvdprofiler2xbmc_cli.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.0.2"])
      s.add_runtime_dependency(%q<xml-simple>, [">= 1.0.12"])
      s.add_runtime_dependency(%q<porras-imdb>, [">= 0.0.5"])
      s.add_runtime_dependency(%q<log4r>, [">= 1.0.5"])
      s.add_runtime_dependency(%q<commandline>, [">= 0.7.10"])
      s.add_runtime_dependency(%q<mash>, [">= 0.0.3"])
      s.add_development_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.0.2"])
      s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
      s.add_dependency(%q<porras-imdb>, [">= 0.0.5"])
      s.add_dependency(%q<log4r>, [">= 1.0.5"])
      s.add_dependency(%q<commandline>, [">= 0.7.10"])
      s.add_dependency(%q<mash>, [">= 0.0.3"])
      s.add_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.0.2"])
    s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
    s.add_dependency(%q<porras-imdb>, [">= 0.0.5"])
    s.add_dependency(%q<log4r>, [">= 1.0.5"])
    s.add_dependency(%q<commandline>, [">= 0.7.10"])
    s.add_dependency(%q<mash>, [">= 0.0.3"])
    s.add_dependency(%q<newgem>, [">= 1.2.3"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
