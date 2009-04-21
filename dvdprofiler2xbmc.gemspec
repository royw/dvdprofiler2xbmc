# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dvdprofiler2xbmc}
  s.version = "0.0.20"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Roy Wright"]
  s.date = %q{2009-04-21}
  s.default_executable = %q{dvdprofiler2xbmc}
  s.email = %q{roy@wright.org}
  s.executables = ["dvdprofiler2xbmc"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "History.txt",
    "Manifest.txt",
    "PostInstall.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "bin/dvdprofiler2xbmc",
    "lib/dvdprofiler2xbmc.rb",
    "lib/dvdprofiler2xbmc/app_config.rb",
    "lib/dvdprofiler2xbmc/controllers/app.rb",
    "lib/dvdprofiler2xbmc/controllers/fanart_controller.rb",
    "lib/dvdprofiler2xbmc/controllers/nfo_controller.rb",
    "lib/dvdprofiler2xbmc/controllers/thumbnail_controller.rb",
    "lib/dvdprofiler2xbmc/models/dvdprofiler_info.rb",
    "lib/dvdprofiler2xbmc/models/imdb_info.rb",
    "lib/dvdprofiler2xbmc/models/media.rb",
    "lib/dvdprofiler2xbmc/models/media_files.rb",
    "lib/dvdprofiler2xbmc/models/tmdb_info.rb",
    "lib/dvdprofiler2xbmc/models/xbmc_info.rb",
    "lib/dvdprofiler2xbmc/open_cache_extension.rb",
    "lib/dvdprofiler2xbmc/views/cli.rb",
    "lib/dvdprofiler2xbmc/views/config_editor.rb",
    "spec/app_spec.rb",
    "spec/config_editor_spec.rb",
    "spec/dvdprofiler2xbmc_spec.rb",
    "spec/fanart_controller_spec.rb",
    "spec/media_spec.rb",
    "spec/nfo_controller_spec.rb",
    "spec/samples/Collection.xml",
    "spec/samples/Die Hard - 1988.nfo",
    "spec/samples/Ma and Pa Kettle.cd1.dummy",
    "spec/samples/The Egg and I.dummy",
    "spec/samples/api.themoviedb.org/2.0/Movie.imdbLookup?imdb_id=tt0039349&api_key=7a2f6eb9b6aa01651000f0a9324db835",
    "spec/samples/api.themoviedb.org/2.0/Movie.imdbLookup?imdb_id=tt0060934&api_key=7a2f6eb9b6aa01651000f0a9324db835",
    "spec/samples/api.themoviedb.org/2.0/Movie.imdbLookup?imdb_id=tt0095016&api_key=7a2f6eb9b6aa01651000f0a9324db835",
    "spec/samples/api.themoviedb.org/2.0/Movie.imdbLookup?imdb_id=tt0108171&api_key=7a2f6eb9b6aa01651000f0a9324db835",
    "spec/samples/api.themoviedb.org/2.0/Movie.imdbLookup?imdb_id=tt0110413&api_key=7a2f6eb9b6aa01651000f0a9324db835",
    "spec/samples/api.themoviedb.org/2.0/Movie.imdbLookup?imdb_id=tt0114924&api_key=7a2f6eb9b6aa01651000f0a9324db835",
    "spec/samples/api.themoviedb.org/2.0/Movie.imdbLookup?imdb_id=tt0465234&api_key=7a2f6eb9b6aa01651000f0a9324db835",
    "spec/samples/www.imdb.com/find?q=%2Abatteries+not+included;s=tt",
    "spec/samples/www.imdb.com/find?q=About+a+Boy;s=tt",
    "spec/samples/www.imdb.com/find?q=Alexander+the+Great;s=tt",
    "spec/samples/www.imdb.com/find?q=Anastasia;s=tt",
    "spec/samples/www.imdb.com/find?q=Call+Me%3A+The+Rise+and+Fall+of+Heidi+Fleiss;s=tt",
    "spec/samples/www.imdb.com/find?q=Captain+Corelli%27s+Mandolin;s=tt",
    "spec/samples/www.imdb.com/find?q=Flyboys;s=tt",
    "spec/samples/www.imdb.com/find?q=Gung+Ho%21;s=tt",
    "spec/samples/www.imdb.com/find?q=Hot+Shots%21;s=tt",
    "spec/samples/www.imdb.com/find?q=Meltdown;s=tt",
    "spec/samples/www.imdb.com/find?q=National+Treasure%3A+Book+of+Secrets;s=tt",
    "spec/samples/www.imdb.com/find?q=National+Treasure+2;s=tt",
    "spec/samples/www.imdb.com/find?q=Oklahoma%21;s=tt",
    "spec/samples/www.imdb.com/find?q=Rooster+Cogburn+%28...and+the+Lady%29;s=tt",
    "spec/samples/www.imdb.com/find?q=The+Alamo;s=tt",
    "spec/samples/www.imdb.com/find?q=The+Egg+and+I;s=tt",
    "spec/samples/www.imdb.com/find?q=The+Man+from+Snowy+River;s=tt",
    "spec/samples/www.imdb.com/find?q=rooster+cogburn;s=tt",
    "spec/samples/www.themoviedb.org/image/backdrops/13391/Sniper_1__Odst%c4%b9%e2%84%a2elova%c3%84%c5%a4_.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/13391/Sniper_1__Odst%c4%b9%e2%84%a2elova%c3%84%c5%a4__poster.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/13391/Sniper_1__Odst%c4%b9%e2%84%a2elova%c3%84%c5%a4__thumb.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/23357/W%c3%a4hrend_Du_schliefst.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/23357/W%c3%a4hrend_Du_schliefst_poster.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/23357/W%c3%a4hrend_Du_schliefst_thumb.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/803/tt0095016.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/803/tt0095016_poster.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/803/tt0095016_thumb.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/8579/L%c3%a9on-fanart.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/8579/L%c3%a9on-fanart_poster.jpg",
    "spec/samples/www.themoviedb.org/image/backdrops/8579/L%c3%a9on-fanart_thumb.jpg",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/xbmc_info_spec.rb",
    "test/test_dvdprofiler2xbmc.rb",
    "test/test_dvdprofiler2xbmc_cli.rb",
    "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/royw/dvdprofiler2xbmc}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{TODO}
  s.test_files = [
    "spec/spec_helper.rb",
    "spec/app_spec.rb",
    "spec/config_editor_spec.rb",
    "spec/fanart_controller_spec.rb",
    "spec/media_spec.rb",
    "spec/nfo_controller_spec.rb",
    "spec/xbmc_info_spec.rb",
    "spec/dvdprofiler2xbmc_spec.rb",
    "test/test_dvdprofiler2xbmc.rb",
    "test/test_helper.rb",
    "test/test_dvdprofiler2xbmc_cli.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.0.2"])
      s.add_runtime_dependency(%q<xml-simple>, [">= 1.0.12"])
      s.add_runtime_dependency(%q<royw-read_page_cache>, [">= 0.0.2"])
      s.add_runtime_dependency(%q<royw-roys_extensions>, [">= 0.0.2"])
      s.add_runtime_dependency(%q<royw-imdb>, [">= 0.1.3"])
      s.add_runtime_dependency(%q<royw-tmdb>, [">= 0.1.6"])
      s.add_runtime_dependency(%q<royw-dvdprofiler_collection>, [">= 0.1.3"])
      s.add_runtime_dependency(%q<log4r>, [">= 1.0.5"])
      s.add_runtime_dependency(%q<commandline>, [">= 0.7.10"])
      s.add_runtime_dependency(%q<mash>, [">= 0.0.3"])
      s.add_runtime_dependency(%q<highline>, [">= 1.5.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.0.2"])
      s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
      s.add_dependency(%q<royw-read_page_cache>, [">= 0.0.2"])
      s.add_dependency(%q<royw-roys_extensions>, [">= 0.0.2"])
      s.add_dependency(%q<royw-imdb>, [">= 0.1.3"])
      s.add_dependency(%q<royw-tmdb>, [">= 0.1.6"])
      s.add_dependency(%q<royw-dvdprofiler_collection>, [">= 0.1.3"])
      s.add_dependency(%q<log4r>, [">= 1.0.5"])
      s.add_dependency(%q<commandline>, [">= 0.7.10"])
      s.add_dependency(%q<mash>, [">= 0.0.3"])
      s.add_dependency(%q<highline>, [">= 1.5.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.0.2"])
    s.add_dependency(%q<xml-simple>, [">= 1.0.12"])
    s.add_dependency(%q<royw-read_page_cache>, [">= 0.0.2"])
    s.add_dependency(%q<royw-roys_extensions>, [">= 0.0.2"])
    s.add_dependency(%q<royw-imdb>, [">= 0.1.3"])
    s.add_dependency(%q<royw-tmdb>, [">= 0.1.6"])
    s.add_dependency(%q<royw-dvdprofiler_collection>, [">= 0.1.3"])
    s.add_dependency(%q<log4r>, [">= 1.0.5"])
    s.add_dependency(%q<commandline>, [">= 0.7.10"])
    s.add_dependency(%q<mash>, [">= 0.0.3"])
    s.add_dependency(%q<highline>, [">= 1.5.0"])
  end
end
