# == Schema Information
#
# Table name: bsp1_payment_processes
#
#  id           :bigint           not null, primary key
#  amount       :decimal(10, 2)
#  data         :jsonb
#  deadline     :string
#  handling_fee :decimal(10, 2)
#  reference    :string
#  status       :string           not null
#  txid         :string
#  userid       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  inquiry_id   :bigint
#
# Indexes
#
#  index_bsp1_payment_processes_on_inquiry_id  (inquiry_id)
#
# Foreign Keys
#
#  fk_rails_...  (inquiry_id => inquiries.id)
#

class Bsp1PaymentProcess < ApplicationRecord
  attr_reader :response

  belongs_to :inquiry, optional: true
  belongs_to :booking, foreign_key: :inquiry_id, optional: true
  belongs_to :reservation, foreign_key: :inquiry_id, optional: true
  has_many :bsp1_responses, foreign_key: :txid, primary_key: :txid
  has_many :payments, through: :bsp1_responses

  include Currency::Model

  after_save :release_reservation, if: :error?

  currency_values :handling_fee

  def booking_or_reservation
    booking || reservation
  end

  def amount_currency
    Currency::Value.new(amount / 100, inquiry.currency)
  end

  def release_reservation
    reservation&.destroy
  end

  def error?
    status == "ERROR"
  end

  def processing?
    created_at > 1.hour.ago && status != "ERROR" && bsp1_responses.finish.blank?
  end

  def pending?
    %w[REDIRECT WAIT].include?(status) && bsp1_responses.blank?
  end

  # Das Formular für die Eingabe der KK-Daten ist ausgeblendet, wenn eine
  # Transaktion offen (pending) ist. Durch das versetzen in den Fehlerzustand
  # wird es wieder eingeblendet, so dass der Kunde seine Daten (oder andere)
  # erneut eingeben kann.
  def restart!
    update status: "ERROR"
  end

  def response=(response)
    self.status = response.status
    self.txid   = response.attributes[:txid]
    self.userid = response.attributes[:userid]
    self.data   = response.attributes
    @response   = response
  end

  module InquiryAssociationExtension
    def make_reference
      if Rails.env.test?
        SecureRandom.base58
      else
        [@association.owner.number, Rails.env[0] + (count + 1).to_s].join("-")
      end
    end

    def authorize(deadline_name)
      inquiry   = @association.owner
      charge    = inquiry.calculate_charge(deadline_name)
      pprocess  = build(deadline: deadline_name)
      reference = make_reference

      auth        = Bsp1::Authorization.from_inquiry(inquiry, reference)
      auth.amount = pprocess.amount = (charge.gross * 100).round

      pprocess.reference    = reference
      pprocess.handling_fee = charge.charge
      pprocess.response     = auth.submit
      pprocess.save!
      pprocess
    end
  end
end
