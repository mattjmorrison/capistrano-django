Gem::Specification.new do |s|

  s.name     = "capistrano-django"
  s.version  = "0.0.3"

  s.homepage = "http://github.com/mattjmorrison/capistrano-django"
  s.summary  = %q{capistrano-django - Welcome to easy deployment with Ruby over SSH for Django}
  s.description = %q{capistrano-django provides a solid basis for common django deployment}

  s.files    = Dir["lib/**/*.rb"]
  s.add_dependency "capistrano", "~> 2.14.1"

  s.author   = "Matthew J. Morrison"
  s.email    = "mattjmorrison@mattjmorrison.com"

end