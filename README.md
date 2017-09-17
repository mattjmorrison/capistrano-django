# Capistrano Django

**A set of tasks built ontop of Capistrano to assist with Django deployments**

example config file:

``` ruby
set :application, 'app_name'
set :scm, :git
set :repo_url, 'git@github.com:username/repo_name.git'
set :django_project_dir, 'src'                          # Where does your Django project live?
set :django_settings_dir, 'app_name/settings'
set :django_settings, 'production'
set :pip_requirements, 'requirements/base.txt'
set :keep_releases, 5
set :nginx, true
set :deploy_to, '/www/app_name.com'
set :wsgi_file, 'app_name.wsgi'
set :npm_tasks, {:grunt => 'do_something', :gulp => 'something_else'}
set :stage, :production
role :web, "user@127.0.0.1"
```

Ordinarily, capistrano-django builds a separate virtualenv per-deploy.

If you include:
``` ruby
set :shared_virtualenv, true
```
in your configuration file, it will instead create a virtualenv in the `shared_path`, and
symlink it into the release path.  It will build it via requirements only when they differ
from those of the last release.

**Author:** Matthew J. Morrison.  [Follow me on Twitter](https://twitter.com/mattjmorrison)
