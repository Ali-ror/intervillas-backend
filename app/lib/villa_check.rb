class VillaCheck
  attr_reader :villa, :checks

  delegate :each, :as_json,
    to: :checks

  def self.check(key, &block)
    checks << [key, block]
  end

  def self.checks
    @checks ||= []
  end

  def initialize(villa)
    @villa  = villa
    @checks = self.class.checks.to_h { |key, chk| [key, chk.call(villa)] }
  end

  def passed?
    checks.values.all? { |(ok, _)| ok }
  end

  check :people_prices do |villa|
    villa.villa_prices.exists?
  end

  check :has_description do |villa|
    desc = villa.descriptions.find_by(key: "description")
    desc&.en_text.present?
  end

  check :clean_description do |villa|
    desc    = villa.descriptions.find_by(key: "description")
    failure = nil

    [desc&.de_text, desc&.en_text].compact_blank.map(&:downcase).each do |text|
      next if failure == true

      failure ||= [
        /\b(?:sales|tourist(?:en))?\s*tax(?:es)?\b/,
        /[€$]|(?:\b(?:euro?|usd|dollar)\b)/,
      ].any? { _1.match?(text) }
    end

    failure.nil? ? nil : !failure
  end

  check :key_collection_placeholder do |villa|
    text = villa.additional_properties_with_defaults
      .fetch("key_collection")
      .fetch("how")

    !text.include?("XXXX")
  end

  check :tags do |villa|
    villa.tags.where.not(amenity_ids: []).exists?
  end

  check :has_bedroom do |villa|
    villa.bedrooms_count > 0
  end

  check :has_bathroom do |villa|
    villa.bathrooms_count > 0
  end

  check :has_image do |villa|
    villa.images.active.count > 0
  end
end
