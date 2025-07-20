class Admin::VillasController < ApplicationController
  include Admin::ControllerExtensions
  authorize_resource :villa
  layout "admin_bootstrap"

  expose :villas do
    current_user.villas.with_owner_manager.includes(
      :domains,
      :route,
      :inclusive_boat,
      :optional_boats,
      :booking_pal_product,
      geocoding: :geocode,
    ).order(:name)
  end

  expose :villa do
    if %w[new create].include?(action_name)
      Villa.new
    else
      current_user.villas.includes(
        :areas,
        :domains,
        :taggings,
        :holiday_discounts,
        descriptions: :translations,
      ).find(params[:id])
    end
  end

  def index
  end

  def edit
    respond_to do |format|
      format.html { render "edit" }
      format.json do
        render json: {
          payload: VillaJSON.new(villa, context: view_context),
        }
      end
    end
  end
  alias new edit

  def create
    save_villa!(:created) { "#{villa_name_with_prefix} erfolgreich erstellt." }
  end

  def update
    save_villa!(:ok) { "#{villa_name_with_prefix} erfolgreich gespeichert." }
  end

  private

  def villa_name_with_prefix
    name = villa.admin_display_name
    name.start_with?("Villa") ? name : "Villa #{name}"
  end

  def villa_params
    params.require(:villa).permit permitted_attributes
  end

  def permitted_attributes
    %i[
      active buyable name safe_code phone manager_id owner_id street
      postal_code locality region country living_area pool_orientation
      build_year last_renovation minimum_booking_nights minimum_people
      energy_cost_calculation
    ] + [{
      calendars:             %i[id _destroy url name],
      domain_ids:            [],
      taggings:              %i[tag_id amount],
      descriptions:          %i[id key category_id de en],
      areas:                 [:id, :_destroy, :category_id, :subtype, :beds_count, { taggings: %i[tag_id amount] }],
      villa_price_eur:       [:_destroy, :currency, *VillaPrice::MONETARY_ATTRIBUTES, { id: [] }],
      villa_price_usd:       [:_destroy, :currency, *VillaPrice::MONETARY_ATTRIBUTES, { id: [] }],
      holiday_discounts:     %i[id _destroy description percent days_before days_after],
      boat:                  [:inclusion, :exclusive_id, { optional_ids: [] }],
      additional_properties: [
        :property_type, :children_allowed, :smoking_allowed,
        {
          pet_policy:      %i[allowed fee],
          internet_policy: %i[available type locations fee],
          parking_policy:  %i[available type private fee fee_unit reservation],
          key_collection:  %i[method how when],
          los:             %i[min_stay max_stay advance_months surcharge],
          extra_tags:      [],
        },
      ],
    }]
  end

  def save_villa!(success_status)
    VueResponse.new(self) do |r|
      VillaStorer.new(villa).store!(villa_params)

      r.success! success_status, yield,
        VillaJSON.new(villa.reload, context: view_context).as_json(include_collections: false)
    rescue ActiveRecord::RecordInvalid => err
      r.error! :unprocessable_entity,
        "Speichern fehlgeschlagen, bitte Fehler prüfen und erneut versuchen.",
        err.record.errors
    rescue ActiveRecord::Rollback
      r.error! :unprocessable_entity,
        "Speichern fehlgeschlagen, bitte Fehler prüfen und erneut versuchen.",
        villa.errors
    end
  end

  # TODO: find better name (not Vue specific, more of a StructuredResponse?)
  class VueResponse
    def initialize(ctrl)
      @ctrl = ctrl
      yield self
    end

    def success!(status, message, payload)
      render status, { payload:, flash: { type: :success, message: } }
    end

    def error!(status, message, errors)
      render status, { errors:, flash: { type: :danger, message: } }
    end

    def render(status, data)
      @ctrl.render :json, status:, json: data
    end
  end

  class VillaJSON < VueAdapter # rubocop:disable Metrics/ClassLength
    KNOWN_DESCRIPTIONS = {
      "accessoires"   => ["accessoires"],
      "bathrooms"     => ["bathrooms"],
      "bedrooms"      => ["bedrooms"],
      "highlights"    => %w[header teaser description],
      "entertainment" => ["entertainment"],
      "gym"           => ["gym"],
      "kitchen"       => ["kitchen"],
      "lavatory"      => ["lavatory"],
      "livingroom"    => ["livingroom"],
      "outdoor"       => ["outdoor"],
      "theme"         => ["theme"],
    }.freeze

    # category names in display order
    CATEGORY_ORDER = %w[
      highlights
      bedrooms
      bathrooms
      kitchen
      lavatory
      livingroom
      entertainment
      outdoor
      location
      theme
      accessoires
      boat
      gym
    ].freeze

    def endpoint_for_vue
      endpoint = {}

      if new_record?
        endpoint[:self]  = context.new_admin_villa_path
        endpoint[:villa] = {
          url:    context.admin_villas_path(format: :json),
          method: "POST",
        }
      else
        endpoint[:self]  = context.edit_admin_villa_path(id)
        endpoint[:villa] = {
          url:    context.admin_villa_path(id, format: :json),
          method: "PATCH",
        }

        %w[images tours pannellums videos].each do |media_type|
          endpoint[media_type] = context.admin_media_gallery_config(__getobj__, media_type)
        end

        endpoint[:reviews] = context.api_admin_reviews_path(villa_id: id, format: :json)
      end

      endpoint
    end

    def attributes_for_vue # rubocop:disable Metrics/AbcSize
      return {} if new_record?

      {
        id:,
        name:,
        minimum_booking_nights:,
        minimum_people:,
        active:,
        buyable:,
        build_year:,
        last_renovation:,
        safe_code:,
        phone:,
        manager_id:,
        owner_id:,
        street:,
        postal_code:,
        locality:,
        region:,
        country:,
        living_area:,
        pool_orientation:,
        latitude:                geocode&.latitude,
        longitude:               geocode&.longitude,
        domain_ids:,
        calendars:               calendars.as_json(only: %i[id url name]),
        descriptions:            to_description_list(descriptions),
        taggings:                taggings.as_json(only: %i[tag_id amount]),
        areas:                   to_area_list(areas),
        villa_price_eur:         villa_price_eur&.as_villa_editor_json,
        villa_price_usd:         villa_price_usd&.as_villa_editor_json,
        cc_fee_usd:              Setting.cc_fee_usd,
        energy_cost_calculation:,
        holiday_discounts:       holiday_discounts.as_json(only: %i[id description days_before days_after percent]),
        boat:                    villa_boat_attributes,
        additional_properties:   additional_properties_with_defaults,
        amenity_ids:             taggings.includes(:tag).flat_map { _1.tag.amenity_ids },
        booking_pal_product:     booking_pal_product&.then { _1.as_json(only: %i[id foreign_id]) },
      }
    end

    def collections_for_vue # rubocop:disable Metrics/AbcSize
      {
        domains:         Domain.all.as_json(only: %i[id name]),
        categories:      sort_categories(Category.includes(tags: :translations).map { |cat|
          {
            id:             cat.id,
            name:           cat.name,
            multiple_types: cat.multiple_types,
            label:          I18n.t(cat.name, scope: "category"),
            descriptions:   KNOWN_DESCRIPTIONS[cat.name]&.map { |key|
              { key:, label: I18n.t(key, scope: "activerecord.attributes.villa", default: "Beschreibung") }
            },
            tags:           cat.tags.map { |tag|
              {
                id:          tag.id,
                countable:   (true if tag.countable?),
                description: tag.description,
                name:        tag.name,
              }.compact
            },
          }.compact
        }),
        contacts:        Contact.all.map { |k|
          {
            id:     k.id,
            name:   k.to_s.presence,
            emails: k.email_addresses,
          }.compact
        },
        exclusive_boats: to_boat_list(Boat.exclusively_assignable | [*inclusive_boat]),
        optional_boats:  to_boat_list(Boat.optionally_assignable),
      }
    end

    private

    def villa_boat_attributes
      if boat_inclusive?
        {
          inclusion:         "inclusive",
          exclusive_boat_id: inclusive_boat.id,
        }
      elsif optional_boats.any?
        { inclusion: "optional", optional_boat_ids: }
      else
        { inclusion: "none" }
      end
    end

    # to_json somehow eager loads boat_translations
    def to_boat_list(boats)
      boats.map { |b|
        { id: b.id, name: b.admin_display_name }
      }
    end

    def sort_categories(list)
      list.sort { |a, b|
        ai = CATEGORY_ORDER.index(a[:name]) || -1
        bi = CATEGORY_ORDER.index(b[:name]) || -1
        return a[:label] <=> b[:label] if ai == bi

        ai - bi
      }
    end

    def to_description_list(descriptions)
      descriptions.map { |desc|
        {
          id:          desc.id,
          key:         desc.key,
          category_id: desc.category_id,
          de:          desc.translations.find { |tr| tr.locale == :de }&.text,
          en:          desc.translations.find { |tr| tr.locale == :en }&.text,
        }
      }
    end

    def to_area_list(areas)
      areas.as_json(
        only:    %i[id category_id subtype beds_count],
        include: [{ taggings: { only: %i[tag_id amount] } }],
      )
    end
  end
  private_constant :VillaJSON
end
