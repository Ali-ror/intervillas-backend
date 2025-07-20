set :branch,    "master"
set :rails_env, "production"
set :deploy_to, "/home/#{fetch(:application)}"

append :linked_files, "config/credentials/production.key"

server "intervillas-florida.com",
  roles: %w[app web db],
  user:  fetch(:application)
