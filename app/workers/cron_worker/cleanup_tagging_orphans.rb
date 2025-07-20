module CronWorker
  class CleanupTaggingOrphans < Base
    daily at: 1.hour

    # Taggings aufräumen, die durch Löschen/Leeren von Schlaf- und Badezimmern übrig geblieben sind
    def perform_non_staging
      Tagging.orphans.each_value(&:destroy_all)
    end
  end
end
