# Capistrano Django

**A set of tasks built ontop of Capistrano to assist with Django deployments**

example config file:

``` ruby
set :application, 'app_name'
set :scm, :git
set :repo_url, 'git@github.com:username/repo_name.git'
set :django_settings_dir, 'app_name/settings'
set :pip_requirements, 'requirements/base.txt'
set :keep_releases, 5
set :nginx, true
set :deploy_to, '/www/app_name.com'
set :wsgi_file, 'app_name.wsgi'
set :npm_tasks, {:grunt => 'do_something', :gulp => 'something_else'}
set :stage, :production
set :django_settings, 'production'
role :web, "user@127.0.0.1"
```

**Author:** Matthew J. Morrison.  [Follow me on Twitter][twitter]
