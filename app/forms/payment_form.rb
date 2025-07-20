class PaymentForm < ModelForm
  from_model :payment

  attr_reader :inquiry
  attr_accessor :comment

  def init_virtual
    @inquiry = payment.inquiry
    @comment = inquiry.comment
  end

  attribute :paid_on, Date
  validates :paid_on,
    presence:     true

  attribute :sum, BigDecimal
  validates :sum,
    numericality: true,
    presence:     true,
    payment:      true

  attribute :scope, String

  def scope=(val)
    # Virtus kommt hier durcheinander und erlaubt "" als Wert,
    # obwohl ModelForm anders konfiguriert ist...
    super val.presence
  end

  def save
    Payment.transaction do
      super
      inquiry.update_attribute :comment, comment.presence
    end
  end
end
