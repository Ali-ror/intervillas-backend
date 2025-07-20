module CronWorker
  class PaymentPrenotification < Base
    daily at: 14.hours

    # Erinnerung an anstehende Zahlung 35 Tage vor der Anreise (nicht, wenn
    # Buchung vollständig bezahlt ist oder Prenotification bereits existiert)
    def perform_non_staging
      Booking.for_payment_prenotification.each(&:send_payment_prenotification)
    end
  end
end
