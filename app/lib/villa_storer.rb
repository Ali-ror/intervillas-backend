# Takes a Villa and saves it to the database.
class VillaStorer # rubocop:disable Metrics/ClassLength
  attr_reader :villa

  def initialize(villa)
    @villa = villa
  end

  def store!(attributes)
    # Remove nested attributes which need special handling (all need to
    # actually be named `*_attributes`; some require further processing).
    # See corresponding `store_*!` methods.
    nested = {
      prices: attributes.extract!(:holiday_discounts, :villa_price_eur, :villa_price_usd),
    }
    %i[taggings areas descriptions boat calendars].each do |f|
      nested[f] = attributes.delete(f)
    end

    Villa.transaction do
      villa.update!(attributes)

      nested.each do |f, attrs|
        send("store_#{f}!", attrs)
      end
    end
  end

  private

  # `to` can be an instance of Villa or Area.
  def store_taggings!(taggings, to: villa) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return unless taggings

    amounts = taggings.each_with_object({}) { |t, list|
      list[t[:tag_id]] = t[:amount] if t[:amount] > 0
    }

    # iterate over existing taggings and update their `amount` fields.
    # if the new amount is <= 0, destroy the tagging. after this block,
    # `amounts` only contains tag IDs for unknown (new) taggings.
    to.taggings.each do |t|
      amount = amounts.delete(t.tag_id)
      if amount.nil? || amount <= 0
        t.destroy!
      elsif t.amount != amount
        # the conditional shouldn't be necessary, but Rails always performs a
        # Tag lookup on Tagging#update!, even if the amount didn't change...
        t.update! amount: amount
      end
    end

    amounts.each do |tag_id, amount|
      to.taggings.create! tag_id: tag_id, amount: amount
    end
  end

  def store_areas!(areas) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    return unless areas

    to_delete = []
    to_update = []
    to_create = []
    areas.each do |a|
      id = a.fetch(:id, nil)

      if a.fetch(:_destroy, false)
        # destroy record with existing id and avoid work if `id.nil?`
        to_delete << id if id
      elsif id
        # updating record with existing id
        to_update << a
      else
        # create new area
        to_create << a
      end
    end

    villa.areas.where(id: to_delete).delete_all unless to_delete.empty?

    to_update.each do |a|
      area = villa.areas.find(a[:id])
      area.update! a.except(:id, :_destroy, :taggings)
      store_taggings! a.fetch(:taggings, false), to: area
    end

    to_create.each do |a|
      area = villa.areas.create! a.except(:_destroy, :taggings)
      store_taggings! a.fetch(:taggings, false), to: area
    end
  end

  def store_descriptions!(descriptions)
    return unless descriptions

    descriptions.each do |d|
      desc = if d[:id]
        villa.descriptions.includes(:translations).find(d[:id])
      else
        villa.descriptions.build(key: d[:key], category_id: d[:category_id])
      end

      desc.de_text = d[:de]
      desc.en_text = d[:en]
      desc.save!
    end
  end

  # `boat` is expected to be a hash in the following shape:
  #
  #   {
  #     inclusion:    "none" | "inclusive" | "optional",
  #     exclusive_id: nil | Boat-ID,         # (required if inclusion == "inclusive", ignored otherwise)
  #     optional_ids: nil | Array[Boat-ID],  # (required if inclusion == "optional", ignored otherwise)
  #   }
  def store_boat!(boat)
    return unless boat

    optional  = []
    inclusive = nil
    case boat[:inclusion]
    when "none"
      # nothing to do
    when "inclusive"
      inclusive = Boat.find_by(id: boat[:exclusive_id])
    when "optional"
      optional = Boat.where(id: boat[:optional_ids])
    end

    villa.update! \
      optional_boats: optional,
      inclusive_boat: inclusive
  end

  # `attrs` is expected to be a hash in the following shape:
  #
  #   {
  #     holiday_discounts: nil | Array[HolidayDiscount],
  #     villa_price_eur:   nil | Hash[attr, value],
  #     villa_price_usd:   nil | Hash[attr, value],
  #   }
  def store_prices!(attrs)
    return if attrs.empty?

    nested = attrs
      .reject { |_, v| v.blank? }
      .transform_keys { |key| "#{key}_attributes" }

    villa.update!(nested)
  end

  def store_calendars!(attrs)
    return unless attrs

    villa.update! calendars_attributes: attrs
  end
end
