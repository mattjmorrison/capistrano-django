set :application, 'test_deploy'
set :scm, :git
set :repo_url, 'https://github.com/mattjmorrison/test_deploy.git'
set :pip_requirements, 'requirements/base.txt'
set :django_settings, 'production'
set :django_settings_dir, 'test_deploy/settings'
set :wsgi_path, 'test_deploy'
set :wsgi_file_name, 'wsgi.py'
set :create_s3_bucket, false

set :aws_access_key, 'asdf'
set :aws_secret_key, 'wxyz'
set :s3_bucket_prefix, 'my-bucket-prefix'
