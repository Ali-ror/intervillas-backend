namespace :load do
  task :defaults do
    set :sidekiq_role, -> { :app }
  end
end

namespace :sidekiq do
  # https://github.com/mperham/sidekiq/wiki/Signals
  def kill_processes(signal)
    return if ENV["SIDEKIQ"] == "0"

    on roles fetch(:sidekiq_role) do
      execute :pkill, "-#{signal} -ef '(sidekiq|puma)' -u '#{fetch(:application)}'",
        raise_on_non_zero_exit: false
    end
  end

  # https://github.com/mperham/sidekiq/wiki/Signals#term
  desc "Terminate sidekiq"
  task :stop do
    kill_processes :TERM
  end

  # https://github.com/mperham/sidekiq/blob/master/5.0-Upgrade.md#whats-new
  # https://github.com/mperham/sidekiq/wiki/Signals#tstp
  desc "Quiet sidekiq (stop accepting new work)"
  task :quiet do
    kill_processes :TSTP
  end

  after "deploy:starting",   "sidekiq:quiet"
  after "deploy:publishing", "sidekiq:stop"
end
