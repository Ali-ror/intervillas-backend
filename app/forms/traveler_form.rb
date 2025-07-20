class TravelerForm < ModelForm
  from_model :traveler, destroyable: true

  attribute :first_name, String
  validates :first_name, presence: true

  attribute :last_name, String
  validates :last_name, presence: true

  attribute :born_on, Date
  validates :born_on, presence: true
end
