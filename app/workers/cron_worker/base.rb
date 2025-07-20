module CronWorker
  class Base
    include Sidekiq::Worker
    extend MiniScheduler::Schedule

    sidekiq_options(
      backtrace: true,
      retry:     false,
    )

    def perform
      perform_non_staging unless Rails.env.staging?
    end

    private

    # Implement this method (instead of #perform), if you want to
    # run your worker only when Rails.env is not "staging". Otherwise
    # overwrite #perform.
    def perform_non_staging
      raise NotImplementedError, "must be implemented in sub-class"
    end
  end
end
