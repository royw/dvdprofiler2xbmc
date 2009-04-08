# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dvdprofiler2xbmc}
  s.version = "0.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Roy Wright"]
  s.date = %q{2009-04-08}
  s.default_executable = %q{dvdprofiler2xbmc}
  s.description = %q{This script will attempt to match up media files from a set of directories to the collection.xml file exported from DVD Profiler.  For matches, the script will then create a {moviename}.nfo from the data in collections.xml and also copy the front cover image to {moviename}.tbn.  Both files will be placed in the same directory as the source media file.  Also the specific profile information for each movie will be saved into {moviename}.dvdprofiler.xml.  The script will then search IMDB for a title or also known as (AKA) match. If necessary, the script will refine the search by using the media year (year in media filename), then dvdprofiler production year, then dvdprofiler release year, then try again with each year plus or minus a year.  The IMDB profile found will be saved as {moviename}.imdb.xml.  Next the script will use the IMDB ID to query themovieDb.com.  This is primarily to retrieve any fanart but will also add any missing parameters to the .nfo file (very unlikely).  The TMDB profile found will be saved as {moviename}.tmdb.xml.  So in summary the files generated are:  {moviename}.tmdb.xml        - profile from themovieDb.com {moviename}.imdb.xml        - profile from imdb.com {moviename}.dvdprofiler.xml - profile from collection.xml {moviename}-fanart.jpg      - first fanart image from themovieDb.com {moviename}.tbn             - image from DVD Profiler {moviename}.nfo             - generated info profile for xbmc  To force regeneration, simply delete these files then run the script again.  Then on XBMC, set the source content to none to remove the meta data from the library, then set the source content back to Movies to import the media. This time, the data in the .nfo files will be used instead of scraping.}
  s.email = ["roy@wright.org"]
  s.executables = ["dvdprofiler2xbmc"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc"]
  s.files = [".gitignore", "History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "bin/dvdprofiler2xbmc", "dvdprofiler2xbmc.gemspec", "lib/dvdprofiler2xbmc.rb", "lib/dvdprofiler2xbmc/app_config.rb", "lib/dvdprofiler2xbmc/controllers/app.rb", "lib/dvdprofiler2xbmc/controllers/fanart_controller.rb", "lib/dvdprofiler2xbmc/controllers/nfo_controller.rb", "lib/dvdprofiler2xbmc/controllers/thumbnail_controller.rb", "lib/dvdprofiler2xbmc/extensions.rb", "lib/dvdprofiler2xbmc/models/collection.rb", "lib/dvdprofiler2xbmc/models/dvdprofiler_profile.rb", "lib/dvdprofiler2xbmc/models/imdb_profile.rb", "lib/dvdprofiler2xbmc/models/media.rb", "lib/dvdprofiler2xbmc/models/media_files.rb", "lib/dvdprofiler2xbmc/models/tmdb_movie.rb", "lib/dvdprofiler2xbmc/models/tmdb_profile.rb", "lib/dvdprofiler2xbmc/models/xbmc_info.rb", "lib/dvdprofiler2xbmc/open_cache_extension.rb", "lib/dvdprofiler2xbmc/views/cli.rb", "spec/cache_extensions.rb", "spec/dvdprofiler2xbmc_spec.rb", "spec/dvdprofiler_profile_spec.rb", "spec/imdb_profile_spec.rb", "spec/nfo_controller_spec.rb", "spec/samples/Collection.xml", "spec/samples/Collection.yaml", "spec/samples/Die Hard - 1988.nfo", "spec/samples/The Egg and I.dummy", "spec/spec.opts", "spec/spec_helper.rb", "spec/tmdb_movie_spec.rb", "spec/tmdb_profile_spec.rb", "spec/xbmc_info_spec.rb", "tasks/rspec.rake", "test/test_dvdprofiler2xbmc.rb", "test/test_dvdprofiler2xbmc_cli.rb", "test/test_helper.rb"]
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
      s.add_runtime_dependency(%q<royw-imdb>, [">= 0.0.16"])
      s.add_runtime_dependency(%q<log4r>, [">= 1.0.5"])
      s.add_runtime_dependency(%q<commandline>, [">= 0.7.10"])
      s.add_runtime_dependency(%q<mash>, [">= 0.0.3"])
      s.add_development_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.0.2"])
      s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
      s.add_dependency(%q<royw-imdb>, [">= 0.0.16"])
      s.add_dependency(%q<log4r>, [">= 1.0.5"])
      s.add_dependency(%q<commandline>, [">= 0.7.10"])
      s.add_dependency(%q<mash>, [">= 0.0.3"])
      s.add_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.0.2"])
    s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
    s.add_dependency(%q<royw-imdb>, [">= 0.0.16"])
    s.add_dependency(%q<log4r>, [">= 1.0.5"])
    s.add_dependency(%q<commandline>, [">= 0.7.10"])
    s.add_dependency(%q<mash>, [">= 0.0.3"])
    s.add_dependency(%q<newgem>, [">= 1.3.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
