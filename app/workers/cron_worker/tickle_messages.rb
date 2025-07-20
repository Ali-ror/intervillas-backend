module CronWorker
  class TickleMessages < Base
    daily at: 15.minutes

    # Nachrichten *nochmal* in den Versand geben. Bleiben manchmal hängen ¯\_(ツ)_/¯
    def perform_non_staging
      Message.where("created_at > ? and sent_at is null", 1.day.ago).find_each(&:deliver!)
    end
  end
end
