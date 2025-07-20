class CableForm < ModelForm

  from_model :cable

  attribute :contact_id, Integer
  validates :contact_id,
    presence: true

  attribute :inquiry_id, Integer
  validates :inquiry_id,
    presence: true

  attribute :text, String
  validates :text,
    presence: true,
    allow_blank: false

  def text=(val)
    super val.to_s.strip.presence
  end

end
