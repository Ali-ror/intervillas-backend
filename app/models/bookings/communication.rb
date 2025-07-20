module Bookings::Communication
  extend ActiveSupport::Concern

  included do
    belongs_to :travel_mail,
      class_name: "Message",
      optional:   true # NULL is allowed

    has_many :messages,
      foreign_key: :inquiry_id,
      inverse_of:  :booking
  end

  # Benachrichtigungen (Mieter, Urs, Eigentümer, Verwaltung) versenden
  def trigger_messages
    send_confirmation_mail # Buchungsbestätigung an Mieter
    send_owner_message     # Buchungsbestätigung an Eigentümer (support#13)
    send_manager_message   # Buchungsbestätigung an Verwaltung (support#206, support#596)
  end

  def send_confirmation_mail
    messages.create! template: "confirmation_mail", recipient: customer
  end

  def deliver_travel_mail(resend: false)
    return if travel_mail.present? && !resend

    self.travel_mail = messages.create! template: "travel_mail", recipient: customer
    save!
  end

  def send_payment_prenotification
    messages.create! template: "payment_prenotification", recipient: customer
  end

  private

  def send_owner_message
    MessageFactory.for(inquiry).build_many("owner").each do |m|
      m.save! if m.recipient.wants_auto_booking_confirmation_mail?
    end
  end

  def send_manager_message
    MessageFactory.for(inquiry).build_many("manager").each do |m|
      m.save! if m.recipient.wants_auto_booking_confirmation_mail?
    end
  end

  module ClassMethods
    NEED_TRAVEL_MAIL_QUERY = <<~SQL.squish.freeze
      select bookings.*
      from bookings
      left outer join messages m    on m.id          = bookings.travel_mail_id
      inner join villa_inquiries vi on vi.inquiry_id = bookings.inquiry_id
      inner join payments_view pv   on pv.inquiry_id = bookings.inquiry_id
      where bookings.travel_mail_id is null
        and vi.start_date >  :start_date
        and vi.start_date <= :end_date
        and ((
          (select sum(total_cache) from clearing_items where inquiry_id = bookings.inquiry_id) - pv.total_payments < :delta
          and pv.external = false
        ) or pv.external = true)
    SQL

    SKIPPED_TRAVEL_MAIL_QUERY = <<~SQL.squish.freeze
      select bookings.*
      from bookings
      left outer join messages m    on m.id          = bookings.travel_mail_id
      inner join villa_inquiries vi on vi.inquiry_id = bookings.inquiry_id
      inner join payments_view pv   on pv.inquiry_id = bookings.inquiry_id
      where bookings.travel_mail_id is null
        and (select sum(total_cache) from clearing_items where inquiry_id = bookings.inquiry_id) - pv.total_payments >= :delta
        and vi.start_date >  :start_date
        and vi.start_date <= :end_date
        and pv.external = false
    SQL

    TRAVEL_MAIL_PAYMENT_DELTA = 150

    # externe und bezahlte interne Buchungen, deren Mieter demnächst eine Nachricht über den
    # bevorstehenden Urlaub bekommen sollen, und die noch keine travel_mail
    # bekommen haben
    def need_travel_mail
      find_by_sql [NEED_TRAVEL_MAIL_QUERY, {
        start_date: 1.day.ago.to_date,
        end_date:   2.weeks.from_now.to_date,
        delta:      TRAVEL_MAIL_PAYMENT_DELTA,
      }]
    end

    # Buchungen, deren Mieter eigentlich demnächst eine Nachricht über den
    # bevorstehenden Urlaub bekommen sollen, aber noch nicht ausreichend
    # Zahlungen hinterlegt haben.
    def skipped_travel_mail
      find_by_sql [SKIPPED_TRAVEL_MAIL_QUERY, {
        start_date: 1.day.ago.to_date,
        end_date:   2.weeks.from_now.to_date,
        delta:      TRAVEL_MAIL_PAYMENT_DELTA,
      }]
    end

    FOR_PAYMENT_PRENOTIFICATION_QUERY = <<~SQL.squish.freeze
      select bookings.*
      from bookings
      inner join payments_view pv on pv.inquiry_id = bookings.inquiry_id
      where pv.diff > 0
        and pv.remainder_date >  :start_date
        and pv.remainder_date <= :end_date
        and bookings.inquiry_id not in (
          select distinct inquiry_id
          from messages m
          where m.template = 'payment_prenotification'
        )
        and pv.external = false
    SQL

    # Buchungen, die demnächst bezahlt werden müssen, und für die noch
    # keine payment_prenotification versandt wurde
    def for_payment_prenotification
      find_by_sql [FOR_PAYMENT_PRENOTIFICATION_QUERY, {
        start_date: 5.days.from_now.to_date,
        end_date:   7.days.from_now.to_date,
      }]
    end
  end
end
