# == Schema Information
#
# Table name: domains
#
#  id               :integer          not null, primary key
#  brand_name       :string           not null
#  content_md       :text
#  default          :boolean          default(FALSE), not null
#  html_title       :string
#  interlink        :boolean          default(FALSE), not null
#  meta_description :string
#  multilingual     :boolean          default(FALSE), not null
#  name             :string(63)       not null
#  page_heading     :string
#  partials         :string           default([]), not null, is an Array
#  theme            :string(20)       not null
#  tracking_code    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_domains_on_name  (name) UNIQUE
#

class Domain < ApplicationRecord
  translates :content_md, :meta_description, :html_title, :page_heading,
    touch: true
  include Digineo::I18n

  # CSS theming (see app/assets/stylesheets/styles)
  THEME_COLORS = {
    "intervillas" => "#75c5cf", # turquoise
    "satellite"   => "#dc7b13", # orange
  }.freeze

  has_and_belongs_to_many :pages
  has_and_belongs_to_many :user
  has_and_belongs_to_many :villas
  has_and_belongs_to_many :boats

  has_many :slides, -> { order(position: :asc) },
    class_name: "Media::Slide",
    as:         "parent"

  strip_attributes

  validates :name, # rubocop:disable Rails/UniqueValidationWithoutIndex
    presence:   true,
    uniqueness: true

  validates :brand_name,
    presence: true

  validates :partials,
    array: { presence: true, inclusion: { in: ->(*) { valid_partial_names } } }

  validates :theme,
    presence:  true,
    inclusion: { in: THEME_COLORS.keys }

  def to_s
    name
  end

  # Although this methods returns a locale suitable for `I18n.locale=`,
  # we can't name this method "locale", as it interferes with Globalize.
  #
  # A domain's locale is determined by the presence of either the DE, or
  # the EN translation of the (Globalize'd) content_md field. It is
  # unspecified if the domain is multilingual.
  #
  # XXX(dom): de_content_md could be `.blank?` as well
  def language_code
    return if multilingual?

    en_content_md.present? ? :en : :de
  end

  def each_partial
    partials.each do |pt|
      yield pt if valid_partial_names.include?(pt)
    end
  end

  def pseudo_route
    @pseudo_route ||= PseudoRoute.new(meta_description, html_title, page_heading)
  end

  def theme_color
    THEME_COLORS[theme] || THEME_COLORS["intervillas"]
  end

  def partials
    # only return existing partials
    (self.class.valid_partial_names & (self[:partials] || [])).to_a
  end

  # behaves like a Route object
  PseudoRoute = Struct.new(:meta_description, :html_title, :h1) # rubocop:disable Naming/VariableNumber
  private_constant :PseudoRoute

  class << self
    def valid_partial_names
      # Cache partial names outside of development only.
      #
      # `@valid_partial_names ||= find_partial_names` would always cache,
      # but in dev, we may need to add or delete partials. Restarting
      # the server becomes annoying.
      @valid_partial_names || find_partial_names.tap do |names|
        @valid_partial_names = names unless Rails.env.development?
      end
    end

    private

    def find_partial_names
      Rails.root.join("app/views/home/dynamic")
        .children.map(&:basename).map(&:to_s)     # only filename
        .select { |n| n.start_with?("_") }        # only partials
        .map    { |n| n[1..-1].split(".").first } # remove clutter
        .to_set                                   # remove duplicates
    end
  end
end
