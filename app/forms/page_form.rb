class PageForm < ModelForm
  include Virtus::Multiparams

  from_model :page

  LOCALIZED_ATTRIBUTES = {
    de_name:    String,
    de_content: String,
    en_name:    String,
    en_content: String
  }.each { |lattr, type| attribute lattr, type }

  ROUTING_ATTRIBUTES = {
    route_path: String
  }.each { |rattr, type| attribute rattr, type }

  PAGE_ATTRIBUTES = {
    domain_ids:   Array[Integer],
    noindex:      Axiom::Types::Boolean,
    published_at: DateTime,
    modified_at:  DateTime
  }.each { |pattr, type| attribute pattr, type }

  attribute :route_name, String
  validates :route_name,
            format:      { with: /\A[_\w]*\z/ },
            allow_blank: false,
            allow_nil:   true

  validates :route_path,
            presence: true,
            format:   { with: %r{\A[^/]} }
  validate :unique_route_path

  delegate :template_path?,
           to: :model

  def init_virtual
    self.domain_ids = model.domain_ids
    self.noindex    = model.noindex
    self.de_name    = de_translation.name.presence
    self.de_content = de_translation.content.presence
    self.en_name    = en_translation.name.presence
    self.en_content = en_translation.content.presence
    self.route_path = route.path
    self.route_name = route.name
  end

  def domain_ids=(list)
    super list.select(&:present?)
  end

  def save
    Page.transaction do
      model.attributes = attributes.slice *PAGE_ATTRIBUTES.keys
      route.path = route_path
      route.name = route_name.presence if route_name_editable?
      de_translation.attributes = { name: de_name, content: de_content }
      en_translation.attributes = { name: en_name, content: en_content }

      model.save!
      route.save!
      de_translation.tap { |t| t.page_id = model.id }.save!
      en_translation.tap { |t| t.page_id = model.id }.save!
    end
  end

  def route_name_editable?
    route.new_record? || route.name.blank?
  end

  private

  def de_translation
    @de_translation ||= find_or_initialize_translation(:de)
  end

  def en_translation
    @en_translation ||= find_or_initialize_translation(:en)
  end

  def route
    @route ||= model.route || model.build_route(controller: "admin/pages", action: "show")
  end

  def find_or_initialize_translation(locale)
    model.translations.find { |tr| tr.locale == locale } ||
      model.translations.build(locale: locale)
  end

  # unique path, scoped to domains array
  #
  #   model.domains   other.domains       error?
  #   []              any                 false
  #   [a]             [], [b], [b,c,…]    false
  #   [a]             [a], [a,b,…]        true
  #   [a,b]           [a], [b], [a,b,…]   true
  def unique_route_path
    return if route_path.blank?

    Page.includes(:domains).joins(:route).where(routes: { path: route_path }).find_each do |other|
      next if other.id == model.id
      next if (other.domain_ids & domain_ids).empty?

      errors.add :route_path, :taken
    end
  end
end
