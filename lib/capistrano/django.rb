after 'deploy:updating', 'python:create_virtualenv'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:web) do |h|
      execute "sudo apache2ctl graceful"
    end
  end

end

namespace :python do

  desc "Create a python virtualenv"
  task :create_virtualenv do
    on roles(:all) do |h|
      execute "virtualenv #{release_path}/virtualenv"
      execute "#{release_path}/virtualenv/bin/pip install -r #{release_path}/#{fetch(:pip_requirements)}"
    end
    if fetch(:flask)
      invoke 'flask:setup'
    else
      invoke 'django:setup'
    end
  end

end

namespace :flask do

  task :setup do
    on roles(:web) do |h|
      execute "ln -s #{release_path}/settings/#{fetch(:settings_file)}.py #{release_path}/settings/deployed.py"
      execute "ln -sf #{release_path}/wsgi/wsgi.py #{release_path}/wsgi/live.wsgi"
    end
  end

end

namespace :django do

  def django(args, flags="")
    on roles(:all) do |h|
      manage_path = File.join(release_path, fetch(:django_project_dir) || '', 'manage.py')
      execute "#{release_path}/virtualenv/bin/python #{manage_path} #{fetch(:django_settings)} #{args} #{flags}"
    end
  end

  desc "Setup Django environment"
  task :setup do
    if fetch(:django_compressor)
      invoke 'django:compress'
    end
    invoke 'django:collectstatic'
    invoke 'django:symlink_settings'
    invoke 'django:symlink_wsgi'
    invoke 'django:migrate'
  end

  desc "Run django-compressor"
  task :compress do
    django("compress")
  end

  desc "Run django's collectstatic"
  task :collectstatic do
    django("collectstatic", "-i *.coffee -i *.less --noinput")
  end

  desc "Symlink django settings to deployed.py"
  task :symlink_settings do
    settings_path = "#{release_path}/#{fetch(:django_settings_dir)}"
    on roles(:all) do
      execute "ln -s #{settings_path}/#{fetch(:django_settings)}.py #{settings_path}/deployed.py"
    end
  end

  desc "Symlink wsgi script to live.wsgi"
  task :symlink_wsgi do
    on roles(:web) do
      wsgi_path = File.join(release_path, fetch(:wsgi_path) || 'wsgi')
      execute "ln -sf #{wsgi_path}/main.wsgi #{wsgi_path}/live.wsgi"
    end
  end

  desc "Run django migrations"
  task :migrate do
    django("syncdb", "--noinput --migrate")
  end

end



#   namespace :nodejs do

#     desc "Install node.js dependencies"
#     task :install_deps do
#       if exists?(:node_dependencies)
#         run "cd #{current_release}/devops && npm install"
#       end
#     end

#   namespace :python do

#     desc "Restart Apache"
#     task :restart_apache do
#       run "sudo apache2ctl graceful"
#     end

#     desc "Restart Celery"
#     task :restart_celery do
#       restart_celeryd
#       restart_celerybeat
#     end

#     desc "Restart Celeryd"
#     task :restart_celeryd do
#       run "sudo service celeryd-django restart"
#     end

#     desc "Restart Celerybeat"
#     task :restart_celerybeat do
#       run "sudo service celerybeat-django restart"
#     end
