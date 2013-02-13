
unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano_django requires Capistrano 2"
end

Capistrano::Configuration.instance.load do

  set :normalize_asset_timestamps, false

  after :deploy, 'deploy:cleanup'
  after 'deploy:update_code', 'nodejs:install_deps'
  after 'deploy:update_code', 'python:create_virtualenv'
  after 'python:create_virtualenv', 'python:install_deps'
  after 'python:install_deps', 'django:compress'
  after 'django:compress', 'django:collectstatic'
  after 'django:collectstatic', 'django:symlink_settings'
  before 'deploy:create_symlink', 'django:migrate'

  namespace :nodejs do

    desc "Install node.js dependencies"
    task :install_deps do
      run "cd #{current_release}/devops && npm install"
    end

  end

  namespace :python do

    desc "Create a python virtualenv"
    task :create_virtualenv do
      run "virtualenv #{current_release}/virtualenv"
    end

    desc "Install python requirements"
    task :install_deps do
      pip = "#{current_release}/virtualenv/bin/pip"
      run "#{pip} install -r #{current_release}/devops/requirements/#{django_env}.txt"
    end

  end

  namespace :django do

    def django(args, flags="")
      python = "#{current_release}/virtualenv/bin/python"
      run "#{python} #{current_release}/manage.py #{django_env} #{args} #{flags}"
    end

    desc "Run django-compressor"
    task :compress do
      django("compress")
    end

    desc "Run django's collectstatic"
    task :collectstatic do
      django("collectstatic", "-i *.coffee -i *.less --noinput")
    end

    desc "Run django migrations"
    task :migrate do
      django("syncdb", "--noinput --migrate")
    end

    desc "Symlink django settings to deployed.py"
    task :symlink_settings do
      run "ln -s #{current_release}/project/settings/#{django_env}.py #{current_release}/project/settings/deployed.py"
    end

  end

  namespace :deploy do

    desc "Restart apache"
    task :restart do
      run "sudo apache2ctl graceful"
      run "sudo service celeryd-django restart"
      run "sudo service celerybeat-django restart"
    end

  end

end
