class TagForm < ModelForm
  from_model :tag

  attribute :de_description,  String
  attribute :en_description,  String

  attribute :category_id,   Integer
  attribute :amenity_ids,   [String]
  attribute :filterable,    Boolean

  attribute :de_name_one,   String
  attribute :de_name_other, String
  attribute :en_name_one,   String
  attribute :en_name_other, String

  validates :de_description, :en_description,
    format:   { without: /%/ },
    presence: true

  validates :category_id,
    presence: true

  validates :de_name_one, :en_name_one,
    format:   { without: /%/ },
    presence: { if: :countable? }

  validates :de_name_other, :en_name_other,
    format:   { without: /%/, unless: :countable? },
    presence: true

  delegate :countable?, :taggings,
    to: :model

  def init_virtual
    self.de_name_one    = de_translation.name_one
    self.de_name_other  = de_translation.name_other
    self.de_description = de_translation.description
    self.en_name_one    = en_translation.name_one
    self.en_name_other  = en_translation.name_other
    self.en_description = en_translation.description
  end

  def save
    de_translation.update(
      name_one:    de_name_one,
      name_other:  de_name_other,
      description: de_description,
    )
    en_translation.update(
      name_one:    en_name_one,
      name_other:  en_name_other,
      description: en_description,
    )
    model.attributes = attributes.except(
      :de_name_one, :de_name_other, :de_description,
      :en_name_one, :en_name_other, :en_description
    )
    model.save
  end

  private

  def de_translation
    @de_translation ||= find_or_initialize_translation(:de)
  end

  def en_translation
    @en_translation ||= find_or_initialize_translation(:en)
  end

  def find_or_initialize_translation(locale)
    model.translations.find { |tr| tr.locale == locale } ||
      model.translations.build(locale: locale)
  end
end
