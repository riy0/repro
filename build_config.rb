MRuby::Build.new('host') do |conf|
  toolchain :gcc

  conf.gembox 'full-core'

  conf.cc do |cc|
    cc.flags << '-fPIC' if ENV['BUILD_DYNAMIC_MODULE']
    cc.flags << ENV['NGX_MRUBY_CFLAGS'] if ENV['NGX_MRUBY_CFLAGS']
  end

  conf.gem './mrbgems/docker'

  conf.gem :github => 'mattn/mruby-json'
  conf.gem :github => 'mattn/mruby-onig-regexp'
  conf.gem :github => 'matsumotory/mruby-sleep'

  # ngx_mruby extended class
  conf.gem './mrbgems/ngx_mruby_mrblib'
end

MRuby::Build.new('test') do |conf|
  # Gets set by the VS command prompts.
  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp
  else
    toolchain :gcc
  end

  enable_debug

  conf.gem :github => 'matsumotory/mruby-simplehttp'
  conf.gem :github => 'matsumotory/mruby-httprequest'
  conf.gem :github => 'matsumotory/mruby-uname'
  conf.gem :github => 'matsumotory/mruby-simpletest'
  conf.gem :github => 'mattn/mruby-http'
  conf.gem :github => 'mattn/mruby-json'
  conf.gem :github => 'iij/mruby-io'
  conf.gem :github => 'iij/mruby-socket'
  conf.gem :github => 'iij/mruby-pack'
  conf.gem :github => 'iij/mruby-env'

  # include the default GEMs
  conf.gembox 'full-core'
end
