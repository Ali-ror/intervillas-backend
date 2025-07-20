module Bookings::Payments
  extend ActiveSupport::Concern

  included do
    has_one :villa_inquiry,
      through: :inquiry

    has_many :inquiry_unions, -> { readonly },
      foreign_key: :inquiry_id,
      autosave:    false

    delegate :late?, :downpayment_percentage,
      to: :payment_deadlines

    delegate :payment_deadlines, :deadline_sum, :payments, :prices_include_cc_fee,
      :bsp1_responses, :bsp1_payment_processes,
      to: :inquiry
  end

  def payment_method
    payments.incoming.last&.scope
  end

  def payment_processing_id
    bsp1_payment_processes.find(&:processing?)&.id
  end

  def paid_total
    Currency::Value.new(self[:paid_total], currency)
  end
end
