# == Schema Information
#
# Table name: messages
#
#  id             :integer          not null, primary key
#  recipient_type :string           not null
#  sent_at        :datetime
#  template       :string           not null
#  text           :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  inquiry_id     :integer          not null
#  recipient_id   :integer          not null
#
# Indexes
#
#  fk__messages_booking_id                            (inquiry_id)
#  fk__messages_recipient_id                          (recipient_id)
#  index_messages_on_recipient_id_and_recipient_type  (recipient_id,recipient_type)
#
# Foreign Keys
#
#  fk_messages_inquiry_id  (inquiry_id => inquiries.id) ON DELETE => cascade
#

class Message < ApplicationRecord # rubocop:disable Metrics/ClassLength
  MailerNotFound = Class.new StandardError

  belongs_to :recipient,
    polymorphic: true

  belongs_to :inquiry

  has_one :booking,
    through: :inquiry

  delegate :email_addresses, :salutation,
    to: :recipient

  scope :template, ->(t) { where template: t }

  after_commit :deliver!, on: :create

  def resend!
    update! sent_at: nil
    deliver!
  end

  def deliver!
    raise ArgumentError, "not saved yet" if new_record?
    return true if sent_at? || inhibit_delivery?

    MailWorker.perform_async("Message", id, "deliver!")
  end

  def sync_deliver!
    return if inhibit_delivery?

    I18n.with_locale(recipient.locale) do
      email_addresses.each do |address|
        message_delivery(address).deliver_now
        update! sent_at: Time.current
      end
    end
  end

  def message_delivery(address)
    mailer_class.send(template, inquiry: inquiry, message: self, to: address)
  end

  def preview
    message_delivery(email_addresses.first)
  end

  def mailer_class
    {
      "reminder_mail"              => InquiryMailer,
      "submission_mail"            => InquiryMailer,

      "confirmation_mail"          => BookingMailer,
      "review"                     => BookingMailer,
      "travel_mail"                => BookingMailer,

      "payment_mail_reloaded"      => PaymentMailer,
      "payment_prenotification"    => PaymentMailer,
      "payment_reminder"           => PaymentMailer,

      # "owner_billing"            => legacy, now either villa_owner_billing or boat_owner_billing
      "boat_owner_billing"         => BillingMailer,
      "tenant_billing"             => BillingMailer,
      "villa_owner_billing"        => BillingMailer,

      "boat_owner_booking_message" => MessageMailer,
      "note_mail"                  => MessageMailer,
      "owner_booking_message"      => MessageMailer,
    }.fetch(template.to_s) {
      raise MailerNotFound, "No Mailer found for #{template}"
    }
  end

  # Stores sent mails, see app/lib/email_storage.rb
  # @param [Mail::Message] mail
  def store_eml(mail)
    msgid = Delivery.safe_message_id(mail)
    dir   = storage_path.tap(&:mkpath)
    path  = dir.join("#{msgid}.eml")
    num   = 0

    begin
      # O_CREAT|O_EXCL will raise EEXIST, if the file already exists.
      # This SHOULD never happen, as msgid SHOULD be unique.
      path.open(File::CREAT | File::WRONLY | File::EXCL, 0o644) do |f|
        f.set_encoding(Encoding::US_ASCII, Encoding::US_ASCII)
        f.write mail.encoded
      end
    rescue Errno::EEXIST
      # try another suffix ("-1", "-2", ...) if msgid is NOT unique
      num += 1
      path = dir.join("#{msgid}-#{num}.eml")
      retry
    end

    path
  end

  Delivery = Struct.new(:path) do
    delegate :exist?, :unlink,
      to: :path

    delegate :header, :to, :from, :subject,
      to: :eml

    def self.safe_message_id(mail_message)
      id = mail_message.message_id

      if (m = id.match(/\A<(.*)>\z/))
        id = m[1]
      end

      id.gsub(/\W/, "_")
    end

    def eml
      @eml ||= ::Mail.read(path)
    end

    def date
      date = eml.header[:date].presence
      return if date.blank?

      Time.zone.parse(date.decoded)
    end

    def message_id
      path.basename.sub_ext("").to_s
    end
  end

  def deliveries
    return [] unless storage_path.exist?

    storage_path.children.sort_by(&:mtime).map { |child|
      Delivery.new(child)
    }
  end

  def delivery(message_id)
    Delivery.new storage_path.join("#{message_id}.eml")
  end

  def delivery?(message_id)
    delivery(message_id).exist?
  end

  # drops modifiers appended to the (raw) text
  def message_text
    text.to_s.split("\x03", 2).first
  end

  private

  def storage_path
    if Rails.env.test?
      Rails.root.join("tmp/data/messages", id.to_s)
    else
      Rails.root.join("data/messages", id.to_s)
    end
  end

  def inhibit_delivery?
    inquiry.cancelled? && template != "note_mail"
  end
end
