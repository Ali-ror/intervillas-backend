# == Schema Information
#
# Table name: booking_pal_products
#
#  id             :integer          not null, primary key
#  status         :integer          default("inactive"), not null
#  status_message :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  foreign_id     :integer
#
# Indexes
#
#  index_booking_pal_products_on_id  (id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (id => villas.id) ON DELETE => cascade
#
module MyBookingPal
  # Beware: Methods with name `*remote*` interact with the MyBookingPal API.
  class Product < ApplicationRecord # rubocop:disable Metrics/ClassLength
    self.table_name  = "booking_pal_products"
    self.primary_key = :id

    belongs_to :villa,
      foreign_key: :id,
      inverse_of:  :booking_pal_product

    has_many :image_imports

    has_many :reservations,
      class_name:  "MyBookingPal::Reservation::Base",
      foreign_key: :villa_id,
      inverse_of:  :product

    enum :status, {
      inactive:            0, # init value, also when validation failed
      queued_validation:   1, # after user trigger, before ProductValidator job finished
      waiting_validation:  2, # pending, waiting for validation notification
      validation_error:    3,
      valid:               4, # MBP response (validation success)
      queued_activation:   5, # after user trigger, before ProductActivator job finished
      queued_deactivation: 6, # after user tritter, before ProductActivator job finished
      activation_error:    7, # after user interaction, after job failed
      active:              8, # MBP response (activation success)
    }, prefix: true

    # inhibits before_save(:update_remote_full!) and is set in ProductUpdateWorker
    attr_accessor :skip_remote_save

    after_destroy :delete_remote!
    after_save    :update_remote_full!, unless: :skip_remote_save

    # Updates the property in MyBookingPal, in an async fashion.
    def update_remote_full!
      Async::ProductUpdater.perform_async id, "start"
    end

    def update_remote_step!(name)
      step = {
        "start"      => :update_remote!,
        "images"     => :update_remote_images!,
        "fees_taxes" => :update_remote_fees!,
        "los_prices" => :update_remote_prices!,
      }.fetch(name) {
        raise ArgumentError, "unknown update step: #{name}"
      }

      progress.reset!(name)
      send(step)
    end

    # Removes the property from their DB. Should be called after destruction
    # of the MyBookingPal::Product.
    def delete_remote!
      return unless foreign_id?

      Async::ProductDeleter.perform_async foreign_id
      progress.destroy!
    end

    def update_remote_prices!
      return unless foreign_id?

      # The iCal worker may create many blockings for the same villa
      # in quick succession. We want to wait for the last blocking to
      # be processed. Using wait < 15s would be fine, but doesn't work
      # well with Sidekiq's polling interval.
      Async::LosPricesPusher.perform_async id,
        bulk: true,
        wait: 15.seconds
    end

    def remote_prices
      return [] unless foreign_id?

      data = MyBookingPal.get "/losrates/#{foreign_id}"

      (data.dig(0, "losRates") || []).map { |entry|
        LengthOfStay::Rate.from_remote(entry)
      }
    end

    def update_remote_fees!
      Async::FeesTaxesPusher.perform_async(id, true)
    end

    def update_remote!
      Async::ProductPusher.perform_async(id, true)
    end

    def update_remote_images!(bulk: false)
      Async::ImagesPusher.perform_async(id, true, bulk:)
    end

    def update_remote_lifecycle!(action_name)
      return unless foreign_id?

      Async::ProductLifeCycler::ACTIONS.fetch(action_name).schedule(foreign_id)
    end

    def sync_remote_images!
      return unless foreign_id?

      result = MyBookingPal.get("/image/#{foreign_id}")
      items  = ImageImport::Item.from_remote result.dig(0, "images")

      transaction {
        image_imports.where.not(medium_id: items.map(&:medium_id)).destroy_all
        items.each_with_index { |item, i| item.import!(image_imports, i + 1) }
      }
    end

    def length_of_stay
      LengthOfStay.new(self)
    end

    def progress
      UpdateProgress.new(id)
    end

    # XXX: Maybe move to Async::ProductPusher? This doesn't really belong here...
    def remote_payload # rubocop:disable Metrics/AbcSize
      teaser_price = Currency.with(Currency::USD) {
        (villa.teaser_price.to_d / villa.minimum_people).round(2)
      }

      data = {
        name:                   villa.display_name,
        altId:                  villa.id,
        rooms:                  villa.bedrooms_count,
        bathrooms:              villa.bathrooms_count,
        toilets:                villa.bathrooms.sum { |b| b.tags.where(name: "wc").count },
        totalBeds:              villa.beds_count,
        space:                  villa.living_area,
        spaceUnit:              "SQ_M",
        persons:                villa.beds_count,
        childs:                 0, # XXX ignore for now
        # latitude:     # we'll provide a location
        # longitude:    # we'll provide a location
        # livingRooms:  # XXX: create Area with type "Living Room"?
        notes:                  {
          description:      { texts: localized_text("description") },
          houseRules:       { texts: localized_house_rules },
          shortDescription: { texts: localized_text("teaser") },
          name:             { texts: [] }, # empty array clears value
          marketingName:    { texts: [] },
        },
        attributesWithQuantity: tags,
        nearbyAmenities:        [],
        propertyType:           additional_properties.fetch(:property_type),
        bedroomConfiguration:   { bedrooms: },
        checkInTime:            "16:00:00",
        checkOutTime:           "08:00:00",
        currency:               Currency::USD,
        policy:                 {
          internetPolicy:  internet_policy,
          parkingPolicy:   parking_policy,
          petPolicy:       pet_policy,
          childrenAllowed: additional_properties.fetch(:children_allowed),
          smokingAllowed:  additional_properties.fetch(:smoking_allowed),
        },
        location:,
        supportedLosRates:      true,
        basePrice:              teaser_price,
        keyCollection:          key_collection,
      }

      if villa.show_reviews?
        data.merge!(
          propertyRating: villa.avg_rating.to_f,
          ratingNumber:   villa.number_of_ratings,
        )
      end

      data[:id]             = foreign_id if foreign_id? # updates require the product ID (not part of URL)
      data[:builtDate]      = "#{villa.build_year}-01-01 00:00:00" if villa.build_year?
      data[:renovationDate] = "#{villa.last_renovation}-01-01 00:00:00" if villa.last_renovation?
      data
    end

    private

    def additional_properties
      @additional_properties ||= villa.additional_properties_with_defaults
    end

    def villa_descriptions
      @villa_descriptions ||= villa.descriptions.where(key: %w[teaser description]).index_by(&:key)
    end

    def localized_text(key)
      desc = villa_descriptions.fetch(key, nil)
      return [] unless desc

      [
        { language: "DE", value: desc.de_text.presence },
        { language: "EN", value: desc.en_text.presence },
      ].select { |t| t[:value] }
    end

    def localized_house_rules
      rules = Snippet.house_rules

      [
        { language: "DE", value: rules.de_content_md },
        { language: "EN", value: rules.en_content_md },
      ]
    end

    def tags
      # villa.taggings take precedence over extra tags (because the former
      # are countable)
      from_tagging = Set.new

      taggings = villa.taggings.includes(tag: :category).flat_map { |tagging|
        tagging.tag.amenity_ids.map { |id|
          from_tagging << id

          {
            attributeId: id,
            quantity:    tagging.amount || 1,
          }
        }
      }.compact

      extra = additional_properties.fetch(:extra_tags, []).map { |id|
        { attributeId: id, quantity: 1 } unless from_tagging.include?(id)
      }.compact

      taggings + extra
    end

    def bedrooms
      villa.bedrooms.includes(:taggings).map { |bedroom|
        {
          beds: {
            bed: bedroom.taggings.map { |tagging|
              {
                bedType: tagging.tag.amenity_ids[0],
                count:   tagging.amount,
              }
            },
          },
          type: "Bedroom",
        }
      }
    end

    def location
      {
        postalCode: villa.postal_code,
        country:    villa.country,
        region:     villa.region,
        city:       villa.locality,
        street:     villa.street,
        zipCode9:   villa.postal_code_plus_four, # rubocop:disable Naming/VariableNumber
      }
    end

    def fee_text(src)
      src[:fee].blank? || src[:fee] == "0" ? "Free" : src[:fee]
    end

    def internet_policy
      src = additional_properties.fetch(:internet_policy)
      return { accessInternet: false } unless src[:available]

      {
        accessInternet:    true,
        kindOfInternet:    {
          "wired"    => "Wired",
          "wireless" => "WiFi",
        }.fetch(src[:type]),
        availableInternet: {
          "all"    => "AllAreas",
          "office" => "BusinessCenter",
          "some"   => "SomeRooms",
        }.fetch(src[:locations]),
        chargeInternet:    fee_text(src),
      }
    end

    def parking_policy
      src = additional_properties.fetch(:parking_policy)
      return { accessParking: false } unless src[:available]

      {
        accessParking:               true,
        locatedParking:              {
          "onsite" => "OnSite",
          "nearby" => "Nearby",
        }.fetch(src[:type]),
        privateParking:              src[:private],
        chargeParking:               fee_text(src),
        timeCostParking:             {
          "stay" => "PerStay",
          "week" => "PerWeek",
          "day"  => "PerDay",
          "hour" => "PerHour",
        }.fetch(src[:fee_unit]),
        necessaryReservationParking: {
          "not_needed"   => "NoReservationNeeded",
          "not_possible" => "NotPossible",
          "required"     => "ReservationNeeded",
        }.fetch(src[:reservation]),
      }
    end

    def pet_policy
      src = additional_properties.fetch(:pet_policy)
      return { allowedPets: "NotAllowed" } unless src[:allowed]

      {
        allowedPets: {
          true      => "Allowed",
          "request" => "AllowedOnRequest",
        }.fetch(src[:allowed]),
        chargePets:  fee_text(src),
      }
    end

    def key_collection
      src = additional_properties.fetch(:key_collection)
      res = {
        type:          "primary",
        checkInMethod: src[:method],
      }

      if src[:how].present? || src[:when].present?
        res[:additionalInfo] = {
          instruction: {
            how:  src[:how].presence,
            when: src[:when].presence,
          }.compact_blank,
        }
      end

      res
    end
  end
end
