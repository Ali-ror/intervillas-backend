module IconHelper
  def fa(name, *other_names, text: nil, reverse: false, **options)
    options[:class] = [
      "fa",
      *FontAwesome.names(name, *other_names),
      *Array(options[:class]),
    ]

    icon = tag.i(**options)
    FontAwesome.join(icon, text, reverse)
  end

  # Taken from font-awesome-rails (FontAwesome::Rails::IconHelper::Private)
  #
  # @api private
  module FontAwesome
    extend ActionView::Helpers::OutputSafetyHelper

    def self.names(*names)
      names.map { |n|
        n = n.to_s                # allow Symbols
        n.gsub!("_", "-")         # :thing_o → 'thing-o'
        n.gsub!(/^x(\d)$/, '\1x') # :x2 → '2x' (better than typing :'2x')

        "fa-#{n}"
      }
    end

    def self.join(icon, text, reverse)
      return icon if text.blank?

      elements = [icon, ERB::Util.html_escape(text)]
      elements.reverse! if reverse

      safe_join(elements, " ")
    end
  end

  # Mapping für ausgewählte Tags (erstmal nur Highlights)
  #   key = Tag#name
  #   value = Name für fa()-Helper
  TAG_ICONS = {
    badezimmer:          :bath,
    boot:                :ship,
    deutschsprprogramme: :tv,
    espressomachine:     :coffee,
    fahrrad:             :bicycle,
    grill:               :cutlery,
    heatedpool:          :life_ring, # O_o
    kajak:               :ship, # O_o
    living_area:         :home,
    mp3player:           :music,
    pooltable:           :dot_circle_o, # Ball?
    pool_orientation:    :compass,
    schlafzimmer:        :bed,
    spa:                 :life_ring, # O_o
    tikihut:             :glass,
    build_year:          :calendar,
    last_renovation:     :paint_brush,
  }.stringify_keys.freeze

  def tag_icon(tag)
    name = tag.respond_to?(:name) ? tag.name : tag.to_s
    icon = TAG_ICONS.fetch(name) {
      # logger.warn "undefined tag icon: #{name}"
      :check_circle
    }

    fa :fw, icon
  end

  NAV_ICONS = {
    villas:     :home,
    boats:      :ship,
    specials:   :tags,
    cape_coral: :map_marker,
    karte:      :map_o,
    reviews:    :thumbs_up,
    more:       :plus,
  }.stringify_keys.freeze

  def nav_icon_with_text(handle)
    icon = NAV_ICONS.fetch(handle)
    text = t handle, scope: "shared.menu"
    fa :fw, icon, text: text, class: "hidden-sm hidden-md"
  end
end
