module Ical
  class Sync
    def self.run(calendar)
      dl = Downloader.new(calendar.url)
      dl.keep_data! if new(dl.events, calendar).run
    rescue RuntimeError => err
      if err.message.include?("Invalid iCalendar input line")
        Sentry.set_extras(calendar_id: calendar.id, calendar_url: calendar.url)

        uri = URI.parse(calendar.url) rescue nil
        Sentry.set_tags(calendar_domain: uri.host) if uri
        raise
      end
    end

    # @!attribute events
    #   @return [Array<Ical::Event>] events
    attr_accessor :events, :villa, :calendar

    # @param [Array<Ical::Event>] events
    # @param [Calendar] calendar
    def initialize(events, calendar)
      self.events   = events
      self.villa    = calendar.villa
      self.calendar = calendar
    end

    def run # rubocop:disable Metrics
      # Villa kann mehrere Kalender enthalten; wir nehmen an, dass UIDs nur
      # pro Kalender eindeutig sind. Die Spec spricht zwar von einer global
      # eindeutigen ID, aber Server-Implementierungen nehmen das häufig nicht
      # ernst...
      scope = villa.blockings.where(calendar_id: calendar.id)

      # Events durchiterieren und Konflikte für Kollisions-Email aufsammeln
      conflicts = events.each_with_object([]) do |event, list|
        # vergangene Events nicht beachten
        next if event.start_date < Date.current

        # für jedes Event ein Blocking erzeugen/aktualisieren
        event_blocking = EventBlocking.create_or_update(event, calendar_id: calendar.id, scope: scope)

        # Keine Eskalation (E-Mail Benachrichtigung) notwendig, wenn
        # - an den Daten sich nichts geändert hat
        next if event_blocking.no_change?

        # - Reisezeitraum verfügbar ist
        next if event_blocking.still_available?

        list << event_blocking.conflicts.flatten
      end

      # Blockings entfernen, die in Events nicht enthalten sind
      ical_uids = events.map(&:uid)
      scope.where.not(ical_uid: nil).find_each do |blocking|
        # Blockierungen, die nicht im aktuellen iCal vorhanden sind und in
        # der Zukunft liegen entfernen.
        # Vergangene gültige Blockierungen behalten für die Statistik.
        next if ical_uids.include?(blocking.ical_uid)
        next if blocking.start_date <= Date.current

        blocking.destroy
      end

      # Konflikte können sich selbst auflösen, wenn einer der Termine upstream
      # gelöscht wurde. Daher einmal prüfen, ob sie noch vorhanden sind.
      sent_mails = false
      conflicts.each do |conflict|
        conflict.each(&:reload)
        AdminMailer.clash(*conflict).deliver
        sent_mails = true
      rescue StandardError
        next
      end

      sent_mails
    end
  end
end
