class ChargesForm < ModelForm
  from_model :charge, destroyable: true

  attribute :amount, Integer
  validates :amount,
    presence:     true,
    numericality: { greater_than: 0, only_integer: true }

  attribute :value, BigDecimal
  validates :value,
    presence:     true,
    numericality: true

  attribute :text, String
  validates :text,
    presence:     true,
    allow_blank:  false

end
