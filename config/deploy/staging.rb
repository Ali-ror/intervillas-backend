set :application, "staging"
set :branch,      proc { `git rev-parse --abbrev-ref HEAD`.chomp }
set :rails_env,   "staging"
set :deploy_to,   "/home/staging"
set :ssh_options, user: fetch(:application)

append :linked_files, "config/credentials/staging.key"

server "intervillas-florida.com",
  roles: %w[app web db],
  user:  fetch(:application)

namespace :staging do
  desc "Sync files and database with production"
  task :sync do
    on release_roles(:web) do
      within release_path do
        execute "bin/sync_staging"
      end
    end
  end
end

before :"bundler:install", :"staging:sync"
