# Die Tasks aus dem Gem `capistrano-local-precompile` sind hierhin kopiert,
# um sie mit Ruby 3.2 funktionsfähig zu machen.
namespace :load do
  desc "Blah blah"
  task :defaults do
    set :assets_dir,  "public/assets"
    set :packs_dir,   "public/packs"
    set :rsync_cmd,   "rsync -av --delete"
    set :assets_role, "web"

    after "bundler:install", "deploy:assets:prepare"
    after "deploy:assets:prepare", "deploy:assets:rsync"
    after "deploy:assets:rsync", "deploy:assets:cleanup"
  end
end

namespace :deploy do
  namespace :assets do
    desc "Remove all local precompiled assets"
    task :cleanup do
      run_locally do
        execute "rm", "-rf", fetch(:assets_dir)
        execute "rm", "-rf", fetch(:packs_dir)
      end
    end

    desc "Actually precompile the assets locally"
    task :prepare do
      run_locally do
        precompile_env = fetch(:precompile_env) || fetch(:rails_env) || "production"
        with rails_env: precompile_env do
          execute "rake", "assets:clobber"
          execute "rake", "assets:precompile"
        end
      end
    end

    desc "Performs rsync to app servers"
    task :rsync do
      on roles(fetch(:assets_role)), in: :parallel do |server|
        run_locally do
          remote_shell = %(-e "ssh -p #{server.port}") if server.port

          commands = %i[assets_dir packs_dir].map { fetch(_1) }.select { Dir.exist?(_1) }.map { |dir|
            "#{fetch(:rsync_cmd)} #{remote_shell} ./#{dir}/ #{server.user}@#{server.hostname}:#{release_path}/#{dir}/"
          }

          commands.each do |command|
            if dry_run?
              SSHKit.config.output.info command
            else
              execute command
            end
          end
        end
      end
    end
  end
end
