# Taken from https://github.com/juanibiapina/capistrano-scm-gitsubmodules
# To support git < 1.7.10

load "capistrano/tasks/git.rake"

namespace :gitsubmodules do

  git_environmental_variables = {
    git_askpass: "/bin/echo",
    git_ssh:     "#{fetch(:tmp_dir)}/git-ssh.sh"
  }

  task :check => 'git:check'

  desc 'Copy repo to releases'
  task create_release: :'git:update' do
    on roles :all do
      with git_environmental_variables do
        within repo_path do
          execute :git, :clone, "-b #{fetch :branch}", '--recursive', '.', release_path
        end
      end
    end
  end
end
