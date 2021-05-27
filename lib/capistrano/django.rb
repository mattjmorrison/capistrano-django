after 'deploy:updating', 'python:create_virtualenv'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    if fetch(:nginx)
      invoke 'deploy:nginx_restart'
    else
      on roles(:web) do |h|
        execute "sudo apache2ctl graceful"
      end
    end
  end

  task :nginx_restart do
    on roles(:web) do |h|
      within release_path do
        pid_file = "#{releases_path}/gunicorn.pid"
        if test "[ -e #{pid_file} ]"
          execute "kill `cat #{pid_file}`"
        end
        execute "virtualenv/bin/gunicorn", "#{fetch(:wsgi_file)}:application", '-c=gunicorn_config.py', "--pid=#{pid_file}"
      end
    end
  end

end

namespace :python do

  def virtualenv_path
    File.join(
      fetch(:shared_virtualenv) ? shared_path : release_path, "virtualenv"
    )
  end

  desc "Create a python virtualenv"
  task :create_virtualenv do
    on roles(:all) do |h|
      execute "virtualenv #{virtualenv_path}"
      execute "#{virtualenv_path}/bin/pip install pip<19.2"
      execute "#{virtualenv_path}/bin/pip install -r #{release_path}/#{fetch(:pip_requirements)}"
      if fetch(:shared_virtualenv)
        execute :ln, "-s", virtualenv_path, File.join(release_path, 'virtualenv')
      end
    end
  end

  desc "Set things up after the virtualenv is ready"
  task :post_virtualenv do
    if fetch(:npm_tasks)
      invoke 'nodejs:npm'
    end
    if fetch(:flask)
      invoke 'flask:setup'
    else
      invoke 'django:setup'
    end
  end

end

after 'python:create_virtualenv', 'python:post_virtualenv'

namespace :flask do

  task :setup do
    on roles(:web) do |h|
      execute "ln -s #{release_path}/settings/#{fetch(:settings_file)}.py #{release_path}/settings/deployed.py"
      execute "ln -sf #{release_path}/wsgi/wsgi.py #{release_path}/wsgi/live.wsgi"
    end
  end

end

namespace :django do

  def django(args, flags="", run_on=:all)
    on roles(run_on) do |h|
      manage_path = File.join(release_path, fetch(:django_project_dir) || '', 'manage.py')
      execute "#{release_path}/virtualenv/bin/python #{manage_path} #{fetch(:django_settings)} #{args} #{flags}"
    end
  end

  after 'deploy:restart', 'django:restart_celery'

  desc "Setup Django environment"
  task :setup do
    if fetch(:django_compressor)
      invoke 'django:compress'
    end
    invoke 'django:compilemessages'
    invoke 'django:collectstatic'
    invoke 'django:symlink_settings'
    if !fetch(:nginx)
      invoke 'django:symlink_wsgi'
    end
    invoke 'django:migrate'
  end

  desc "Compile Messages"
  task :compilemessages do
    if fetch :compilemessages
      django("compilemessages")
    end
  end

  desc "Restart Celery"
  task :restart_celery do
    if fetch(:celery_name)
      invoke 'django:restart_celeryd'
      invoke 'django:restart_celerybeat'
    end
    if fetch(:celery_names)
      invoke 'django:restart_named_celery_processes'
    end
  end

  desc "Restart Celeryd"
  task :restart_celeryd do
    on roles(:jobs) do
      execute "sudo service celeryd-#{fetch(:celery_name)} restart"
    end
  end

  desc "Restart Celerybeat"
  task :restart_celerybeat do
    on roles(:jobs) do
      execute "sudo service celerybeat-#{fetch(:celery_name)} restart"
    end
  end

  desc "Restart named celery processes"
  task :restart_named_celery_processes do
    on roles(:jobs) do
      fetch(:celery_names).each { | celery_name, celery_beat |
        execute "sudo service celeryd-#{celery_name} restart"
        if celery_beat
          execute "sudo service celerybeat-#{celery_name} restart"
        end
      }
    end
  end

  desc "Run django-compressor"
  task :compress do
    django("compress")
  end

  desc "Run django's collectstatic"
  task :collectstatic do
    if fetch(:create_s3_bucket)
      invoke 's3:create_bucket'
      on roles(:web) do
        django("collectstatic", "-i *.coffee -i *.less -i node_modules/* -i bower_components/* --noinput --clear")
      end
    else
      django("collectstatic", "-i *.coffee -i *.less -i node_modules/* -i bower_components/* --noinput")
    end

  end

  desc "Symlink django settings to deployed.py"
  task :symlink_settings do
    settings_path = File.join(release_path, fetch(:django_settings_dir))
    on roles(:all) do
      execute "ln -s #{settings_path}/#{fetch(:django_settings)}.py #{settings_path}/deployed.py"
    end
  end

  desc "Symlink wsgi script to live.wsgi"
  task :symlink_wsgi do
    on roles(:web) do
      wsgi_path = File.join(release_path, fetch(:wsgi_path, 'wsgi'))
      wsgi_file_name = fetch(:wsgi_file_name, 'main.wsgi')
      execute "ln -sf #{wsgi_path}/#{wsgi_file_name} #{wsgi_path}/live.wsgi"
    end
  end

  desc "Run django migrations"
  task :migrate do
    if fetch(:multidb)
      django("sync_all", '--noinput', run_on=:jobs)
    else
      django("migrate", "--noinput", run_on=:jobs)
    end
  end
end

namespace :nodejs do

  desc 'Install node modules'
  task :npm_install do
    on roles(:web) do
      path = fetch(:npm_path) ? File.join(release_path, fetch(:npm_path)) : release_path
      within path do
        execute 'npm', 'install', fetch(:npm_install_production, '--production')
      end
    end
  end

  desc 'Run npm tasks'
  task :npm do
    invoke 'nodejs:npm_install'
    on roles(:web) do
      path = fetch(:npm_path) ? File.join(release_path, fetch(:npm_path)) : release_path
      within path do
        fetch(:npm_tasks).each do |task, args|
          execute "./node_modules/.bin/#{task}", args
        end
      end
    end
  end

end


before 'deploy:cleanup', 's3:cleanup'

namespace :s3 do

  desc 'Clean up old s3 buckets'
  task :cleanup do
    if fetch(:create_s3_bucket) and fetch(:delete_old_s3_buckets, true)
      raw_directories = []
      on roles(:web) do
        releases = capture(:ls, '-xtr', releases_path).split
        if releases.count >= fetch(:keep_releases)
          raw_directories.concat releases.last(fetch(:keep_releases))
        else
          raw_directories.concat releases
        end
      end
      directories = raw_directories.uniq
      require 'fog'
      storage = Fog::Storage.new({
        aws_access_key_id: fetch(:aws_access_key),
        aws_secret_access_key: fetch(:aws_secret_key),
        provider: "AWS"
      })
      buckets = storage.directories.all.select { |b| b.key.start_with? fetch(:s3_bucket_prefix) }
      buckets = buckets.select { |b| not directories.include?(b.key.split('-').last) }
      buckets.each do |old_bucket|
        files = old_bucket.files.map{ |file| file.key }
        storage.delete_multiple_objects(old_bucket.key, files) unless files.empty?
        storage.delete_bucket(old_bucket.key)
      end
    end
  end

  desc 'Create a new bucket in s3 to deploy static files to'
  task :create_bucket do
    settings_path = File.join(release_path, fetch(:django_settings_dir))
    s3_settings_path = File.join(settings_path, 's3_settings.py')
    bucket_name = "#{fetch(:s3_bucket_prefix)}-#{asset_timestamp.sub('.', '')}"

    on roles(:all) do
      execute %Q|echo "STATIC_URL = 'https://s3.amazonaws.com/#{bucket_name}/'" > #{s3_settings_path}|
      execute %Q|echo "AWS_ACCESS_KEY_ID = '#{fetch(:aws_access_key)}'" >> #{s3_settings_path}|
      execute %Q|echo "AWS_SECRET_ACCESS_KEY = '#{fetch(:aws_secret_key)}'" >> #{s3_settings_path}|
      execute %Q|echo "AWS_STORAGE_BUCKET_NAME = '#{bucket_name}'" >> #{s3_settings_path}|
      execute %Q|echo 'from .s3_settings import *' >> #{settings_path}/#{fetch(:django_settings)}.py|
      execute %Q|echo 'STATICFILES_STORAGE = "storages.backends.s3boto.S3BotoStorage"' >> #{settings_path}/#{fetch(:django_settings)}.py|
    end

    require 'fog'
    storage = Fog::Storage.new({
      aws_access_key_id: fetch(:aws_access_key),
      aws_secret_access_key: fetch(:aws_secret_key),
      provider: "AWS"
    })
    storage.put_bucket(bucket_name)
    storage.put_bucket_policy(bucket_name, {
      'Statement' => [{
      'Sid' => 'AddPerm',
      'Effect' => 'Allow',
      'Principal' => '*',
      'Action' => ['s3:GetObject'],
      'Resource' => ["arn:aws:s3:::#{bucket_name}/*"]
      }]
    })
    storage.put_bucket_cors(bucket_name, {
      "CORSConfiguration" => [{
        "AllowedOrigin" => ["*"],
        "AllowedHeader" => ["*"],
        "AllowedMethod" => ["GET"],
        "MaxAgeSeconds" => 3000
      }]
    })

  end

end
