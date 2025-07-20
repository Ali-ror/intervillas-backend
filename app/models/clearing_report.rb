# == Schema Information
#
# Table name: clearing_reports
#
#  contact_id      :integer          not null
#  created_at      :datetime         not null
#  id              :integer          not null, primary key
#  reference_month :date             not null
#  sent_at         :datetime
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_clearing_reports_on_contact_id                      (contact_id)
#  index_clearing_reports_on_contact_id_and_reference_month  (contact_id,reference_month)
#
# Foreign Keys
#
#  fk_clearing_reports_contact_id  (contact_id => contacts.id) ON DELETE => cascade
#

#
# Ein ClearingReport wird erzeugt, wenn eine Monatsübersicht an einen
# Eigentümer versandt wird (/admin/billings/clearings).
#
# TODO: Der Versandmechanismus (`after_create :deliver!`, `def deliver!`
#       und `def sync_deliver!`) hat recht große Ähnlichkeit mit dem in
#       Message (das war tatsächlich Copy/Paste).
#
class ClearingReport < ApplicationRecord
  belongs_to :contact

  validates :reference_month,
    presence: true

  delegate :email_addresses, :salutation,
    to: :contact

  after_create :deliver!

  LAST_MAIL_SENT_WINDOW = <<~SQL.squish.freeze
    (
      select  *, rank() over (
        partition by contact_id, reference_month
        order by created_at desc
      ) as __rank_for_contact
      from clearing_reports
    ) as t
  SQL

  scope :by_last_mail_sent_in, ->(date) {
    # ein "select * exepct __rank_for_contact" wäre cool zu haben
    select("t.*").from(LAST_MAIL_SENT_WINDOW).where(t: {
      __rank_for_contact: 1,
      reference_month:    date.to_date.change(day: 1),
    })
  }

  def deliver!
    raise ArgumentError, "not saved yet" if new_record?
    return true if sent_at?

    MailWorker.perform_in 30, "ClearingReport", id, "deliver!"
  end

  def sync_deliver!
    I18n.with_locale(contact.locale) do
      email_addresses.each do |address|
        BillingMailer.clearing_report(
          clearing: clearing,
          to:       address,
        ).deliver_now

        update! sent_at: Time.current
      end
    end
  end

  def clearing(reload = false)
    @clearing   = false if reload
    @clearing ||= Clearing.new(contact, reference_month)
  end

  class Collection
    attr_reader :contacts, :reference_month, :pdf_name

    def initialize(contacts, reference_month)
      @contacts         = contacts
      @reference_month  = reference_month

      y         = reference_month.year
      m         = reference_month.month
      @pdf_name = format "billing-collection_%d-%02d.pdf", y, m
    end

    def pdf_path
      case (paths = clearing_pdf_paths).size
      when 0
        raise ArgumentError, "cannot compile 0 PDF statements"
      when 1
        # no need to invoke pdftk
        paths[0]
      else
        # compile into new PDF
        Pdftk.join(*paths, dest: Rails.root.join("data/billings", pdf_name))
      end
    end

    private

    def clearing_pdf_paths
      contacts.flat_map do |contact|
        Clearing.new(contact, reference_month).pdf_paths
      end
    end
  end

  class Clearing
    attr_reader :contact, :month

    def initialize(contact, month)
      @contact    = contact
      @month      = month
    end

    Currency = Struct.new(:currency, :billings)

    def currencies
      billings.group_by(&:currency).map { |curr, b|
        Currency.new(curr, b)
      }
    end

    def with_compiled_pdf
      case (paths = pdf_paths).size
      when 0
        raise ArgumentError, "cannot compile 0 PDF statements"
      when 1
        # no need to invoke pdftk
        yield paths[0].read
      else
        yield Pdftk.join(*paths)
      end
    end

    def billings
      @billings ||= collect_billings
    end

    def inquiry_ids
      @inquiry_ids ||= collect_inquiry_ids
    end

    def pdf_paths
      billings.map { |b|
        b.pdf.save(force: ->(path) {
          b.billables.any? { |bb| bb.updated_at > path.mtime }
        })
      }
    end

    private

    def collect_inquiry_ids
      [
        @contact.owned_villa_inquiries,
        @contact.owned_boat_inquiries,
      ].inject(Set.new) { |set, scope|
        set + scope
          .includes(inquiry: :booking)
          .where(bookings: { summary_on: @month })
          .map(&:inquiry_id)
      }.sort
    end

    def collect_billings
      Inquiry.includes(
        :boat_billings,
        :villa_billings,
        :customer,
        :booking,
        :cancellation,
      )
        .where(id: inquiry_ids)
        .flat_map { |inq| inq.to_billing.owner_billings }
        .select   { |ob| ob.owner.id == @contact.id }
    end
  end
end
