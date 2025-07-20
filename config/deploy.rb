set :application,     "intervillas"
set :repo_url,        "gitlab@git.digineo.de:intervillas/rails.git"
set :log_level,       :info

set :linked_dirs,     %w[data log tmp/pids tmp/sockets]

set :keep_releases,   5
set :ssh_options,     user: fetch(:application)
set :bundle_without,  "development deployment test"
set :packs_dir,       "public/vite"

set :sentry_project,  "intervillas"

namespace :deploy do
  after :finishing, :cleanup
  after :finished, "assets:restore_dev"

  namespace :assets do
    # capistrano-local-compile installs NPM modules in production mode,
    # but doesn't restore the development environment afterwards. This
    # fixes this by running yarn another time.
    task :restore_dev do
      run_locally do
        with rails_env: "development" do
          execute "yarn", "-s"
        end
      end
    end

    # capistrano-local-compile also removes the public/assets directory,
    # however, we (mis-) use it as a place for some static images
    Rake::Task["deploy:assets:cleanup"].clear

    # from https://github.com/stve/capistrano-local-precompile/blob/40cbbcf/lib/capistrano/local_precompile.rb#L17-L22
    task :cleanup do
      run_locally do
        # execute "rm", "-rf", fetch(:assets_dir)
        execute "rm", "-rf", fetch(:packs_dir)
      end
    end
  end
end
