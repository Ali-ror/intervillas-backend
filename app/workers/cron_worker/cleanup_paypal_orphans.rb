module CronWorker
  class CleanupPaypalOrphans < Base
    daily at: 10.hours + 42.minutes

    # Wenn eine Paypal-Zahlung angefangen aber nicht verfollständigt wird (und der
    # Nutzer den "Zurück"-Button im Browser nutzt), bleiben PaypalPayments mit Status
    # "created" übrig. Die werden nach 14 Tagen ungültig und können aufgeräumt werden.
    def perform_non_staging
      return if Date.current.wday == 6 # only on Saturday

      PaypalPayment.orphaned.destroy_all
    end
  end
end
