set :stage, :vagrant
server 'localhost', user: 'vagrant', roles: %w{web jobs}, password: 'vagrant', port: 2222
