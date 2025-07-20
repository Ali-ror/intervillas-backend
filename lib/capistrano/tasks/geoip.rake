namespace :geoip do
  desc "Update GeoIP database"
  task :update do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "geoip:update"
        end
      end
    end
  end
end

before "deploy:restart", "geoip:update"
