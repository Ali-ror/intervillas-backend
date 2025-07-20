if defined? Sidekiq
  require "sidekiq/web"
  require "mini_scheduler/web"
end

Rails.application.routes.draw do
  # <media-routes>
  #
  # This is black magic. It allows linking to various media presets:
  # - media_url(Media::Image.last, preset: :admin_thumb)
  # - media_path(Media::Image.last, preset: :full)
  #
  # Bonus features:
  # - `media_url` and `media_path` are now accessible from both views
  #   and controllers (and Rails.application.routes.url_helpers), which
  #   beats having a `MediaHelper` (or a controller mixin which defines
  #   such helper method).
  # - `url_for(Media::Image.last, preset: :thumb)` and other route helpers
  #   work as expected.
  direct :media do |medium, options|
    blob_id  = medium.blob_id
    name     = options.fetch(:name, medium.filename_without_extension)
    preset   = options.fetch(:preset)
    dpr      = options.fetch(:dpr, 1)
    checksum = ImgProxy.generate_checksum(blob_id, preset, name)

    path  = "/p/#{blob_id}/#{preset}/#{checksum}/#{name}"
    path << "@#{dpr}x" if dpr && dpr > 1

    unless options[:only_path]
      # try asset host (blank in dev/test)
      host = ActionController::Base.asset_host

      # construct host from default url options
      if (opts = _routes.default_url_options).presence
        host ||= ActionDispatch::Http::URL.send :build_host_url,
          opts[:host],
          opts[:port],
          opts[:protocol],
          opts,
          ""
      end

      path = File.join(host, path) if host.present?
    end

    path
  end

  resolve("Media::Image")    { |m, options| route_for :media, m, options }
  resolve("Media::Pannelum") { |m, options| route_for :media, m, options }
  resolve("Media::Video")    { |m, options| route_for :media, m, options }
  resolve("Media::Slide")    { |m, options| route_for :media, m, options }
  # omitted Medium subclasses:
  #
  # Media::Panorama:
  #   Those are Flash/SWF tours, and not supported by Browsers anymore.
  # Media::Tour:
  #   These are full (micro-) sites, which need to be embedded in IFrames.
  #
  # </media-routes>

  # <localized-routes>
  #
  # The following block is responsible to redirect unlocalized routes to their
  # localized counterpart
  get '/ferienhaus-cape-coral/unavailable_dates', to: 'villas#unavailable_dates'
  get "/villas/search" => "villa_searches#redirect_unlocalized", as: nil
  get "/villas/:id/gallery" => "villas#gallery", as: nil
  get "/villas/:villa_id/bewertungen" => "reviews#redirect_unlocalized", as: nil
  get "/villas(/:id)" => "villas#redirect_unlocalized", as: nil
  get "/villa", to: redirect("/villas"), as: nil

  # We need `resources :villa` for the (nested) routing helper methods.
  resources :villas, only: [] do
    resources :villa_inquiries, only: %i[new create edit], path: "inquiries"

    get "bookings/:token" => "bookings#redirect_new"
    get "bookings/:token/edit" => "bookings#redirect_new"

    resources :reviews, only: %i[show edit update] do
      post :preview, on: :member
    end

    resources :tour, only: :show do
      get "*rest", on: :member, action: "show", format: false, as: :tour_direct
    end
  end

  resources :villas, only: [:index, :show]

  # The following two blocks define the localized routes. They should be identical
  # in structure, apart from the obviously localized `path:` key.
  #
  # Note the `as:` routing prefix on the scope, which is needed for LocalizedRoutes
  # (see app/controllers/concerns/localized_routes.rb) to generate the correct
  # URL/Path based on the current value of `I18n.locale`.
  scope constraints: LocaleDomain::Constraint.new(:de), as: :de, locale: "de" do
    resources :villa_searches, only: %i[index create], path: "/ferienhaus-cape-coral/suche"
    resources :villas, only: %i[index show], path: "/ferienhaus-cape-coral" do
      get :gallery, on: :member
      post :track_map, path: "/map", to: "maps#api_key", as: nil
      resources :reviews, only: [:index], path: "bewertungen"
      get "bewertungen", to: "reviews#index", page: 1
    end
    resources :reviews, only: [:index], path: "bewertungen"
    get "bewertungen", to: "reviews#index", page: 1
  end

  scope constraints: LocaleDomain::Constraint.new(:en), as: :en, locale: "en" do
    resources :villa_searches, only: %i[index create], path: "/vacation-rentals-cape-coral/search"
    resources :villas, only: %i[index show], path: "/vacation-rentals-cape-coral" do
      get :gallery, on: :member
      post :track_map, path: "/map", to: "maps#api_key", as: nil
      resources :reviews, only: [:index], path: "reviews"
      get "reviews", to: "reviews#index", page: 1
    end
    resources :reviews, only: [:index], path: "reviews"
    get "reviews", to: "reviews#index", page: 1
  end
  # </localized-routes>

  get "inquiries/processing",
    to: "conversion_tracker#show",
    as: :inquiry_processing

  scope "inquiries/:token" do
    get "boat" => "boat_inquiries#edit", as: :inquiry_boat_inquiry
    patch "boat" => "boat_inquiries#update", as: nil

    get "book" => "bookings#new", as: :new_booking
    post "book" => "bookings#create", as: :villa_bookings

    get "confirmation" => "bookings#confirmation", as: :confirmation_booking

    resource :customer, only: %i[new create], path_names: { new: "" }
    resources :payments, only: :index
  end

  resources :boats, only: [:show, :index]
  resources :specials, only: [:index]
  resource :map, only: [:show], as: :karte, path: "karte" do
    post :api_key, on: :collection, path: "/", as: nil
  end

  get "/kontakt", to: redirect("/#contact"), as: nil
  get "/admin", to: "admin/overview#index", as: :user_root

  namespace :admin do
    root to: "overview#index"

    resources :high_seasons, only: %i[index new create edit update destroy]

    get "/stats(/:type/:id)",
      to:          "stats#show",
      as:          :stats,
      constraints: { type: /(villa|boat)s/ }

    resources :comparisons, path: "stats/compare", only: %i[index]

    resources :villas, only: %i[index new create edit update] do
      collection do
        get "occupancies" => "occupancies#index", type: "villas"
      end

      member do
        get :price
        get "occupancies"          => "occupancies#show",     type: "villas"
        get "occupancies/calendar" => "occupancies#calendar", type: "villas"
      end

      resource :boat_assignment, only: %i[edit update]
    end

    resources :boats, only: %i[edit index update new create destroy] do
      get "occupancies" => "occupancies#index", type: "boats", on: :collection
      member do
        get "occupancies" => "occupancies#show", type: "boats"
        get "occupancies/calendar" => "occupancies#calendar", type: "boats"
      end
    end

    resources :inquiries, only: %i[index new show edit update destroy] do
      collection do
        get :search, to: "inquiries#search_by_id"
        get :search_name
      end

      member do
        post :mail
      end

      resources :booking_pal_reservations,
        controller: "my_booking_pal/reservations",
        only:       %i[show index]
      resources :cables, only: %i[create destroy]
      resources :messages, only: %i[create show] do
        post :resend, on: :member
        post :live_preview, on: :collection
      end
      resources :payments, only: %i[create edit update destroy]
    end

    resources :billings, only: %i[index edit update show] do
      collection do
        get :search, to: "billings#search_by_id"
        get :invoicable, to: "billings#invoicable"
      end

      member do
        get "/owner-billing/:owner_id", action: "owner_billing", as: :owner
        get "/tenant-billing", action: "tenant_billing", as: :tenant
      end

      resources :messages, only: :create
    end

    resources :bookings, only: %i[index show edit update] do
      member do
        post :mail
        post :travel_mail
      end

      collection do
        resources :summaries, only: :index
      end

      get "/preview",
        to:            "previews#show",
        on:            :member,
        as:            :preview,
        mailer_class:  "BookingMailer",
        mailer_action: "confirmation_mail"

      resources :messages, only: :create
    end

    resources :cancellations, only: %i[index show edit update]

    resources :clearings, only: :index do
      post :deliver, action: :deliver_single, on: :member # params[id] == customer_id
      post :deliver, action: :deliver_all, on: :collection
    end

    get "/grid/:year/:month",
      to:          "grid#index",
      as:          :grid,
      defaults:    { variant: "grid" },
      constraints: { year: /\d\d\d\d/, month: /\d\d?/ }

    get "/grid/slice(/:start_date(/:end_date))",
      to:          "grid#index",
      as:          :grid_slice,
      defaults:    { variant: "slice" },
      constraints: { start_date: /\d\d\d\d-\d\d-\d\d/, end_date: /\d\d\d\d-\d\d-\d\d/ }

    resources :messages, only: :index
    resources :blockings, only: %i[new create edit update destroy show] do
      post :ignore, on: :member
    end

    resources :customers, only: %i[update] do
      match "/search",
        to:  "customer_searches#index",
        via: %i[get post],
        on:  :collection
      get :export, on: :collection
    end

    resources :domains, only: %i[index new create edit update destroy] do
      get "preview", on: :member, to: "domain_preview#show"
    end

    resources :snippets, only: %i[index new create edit update destroy]

    devise_for :users,
      singular:    :user,
      controllers: {
        sessions:  "admin/devise/sessions",
        passwords: "admin/devise/passwords",
        unlocks:   "admin/devise/unlocks",
      }

    as :user do
      get "password/edit" => "devise/registrations#edit", as: :edit_user_registration
      put "password" => "devise/registrations#update", as: :user_registration

      resource :two_factor_settings, only: %i[edit create update destroy]
    end

    resources :users do
      post :signin, on: :member
    end

    resources :contacts

    resources :routes, only: %i[index edit update]
    resources :pages
    resources :reviews, only: %i[index create update] do
      patch :toggle_publish, on: :member, path: "publish"
      patch :toggle_archive, on: :member, path: "archive"
    end

    resources :specials, except: [:show]

    resources :payments, only: :index do
      collection do
        get "overdue",       action: :overdue,  as: :overdue
        get "external",      action: :external, as: :external
        get "balance/:year", action: :balance,  as: :balance
        get "unpaid",        action: :unpaid,   as: :unpaid
        get "acked",         action: :acked,    as: :acked
      end
    end

    resources :paypal_transactions, only: %i[index show], path: "/payments/paypal"
    resources :bsp1_payment_processes, only: %i[index show], path: "/payments/bsp1" do
      patch :restart, on: :member
    end

    resources :settings, only: %i[index update]
    resources :tags, only: %i[index edit update]

    resources :sales, only: %i[index]

    get "my_booking_pal", to: redirect("/admin/my_booking_pal/products", status: 302)

    namespace :my_booking_pal do
      resource :channel, only: :show do
        # channel_connector_url is dynamically generated
        get("/wizard", to: redirect(status: 302) { MyBookingPal.client.channel_connector_url })
      end
      resource :manager, only: %i[show update]
      resource :push_notification, only: %i[show update]
      resources :products do
        resources :image_imports, only: %i[index create]
        resource :life_cycles, only: %i[show update]
        resources :reservations, only: %i[index show]
      end
      resources :reservations, only: %i[index show]
      resources :request_logs, only: :index
    end
  end

  namespace :api do
    resource  :localization, only: :update
    resources :contacts,     only: :create
    resource  :metrics,      only: :show

    scope path: "/inquiries", as: :inquiries do
      get "/clearing(.:format)", to: "clearings#new"
    end

    namespace :admin do
      resources :address_completions, only: :create
      resources :boat_prices,         only: %i[show update]
      resources :bookings,            only: :index
      resources :cancellations,       only: %i[create destroy]
      resources :reviews,             only: %i[index update destroy]

      resource :high_seasons, only: :show, path: "villas/:villa_id/high_seasons"

      resources :inquiries, only: %i[index update create] do
        put "discounts/:kind/:subject", to: "inquiry_discounts#update"
      end

      resources :payments, only: :update
      resources :boat_occupancies, only: :show

      resources :media,
        only:        %i[index create update destroy],
        path:        "media/:rentable_type/:rentable_id/:media_type",
        constraints: {
          rentable_type: /(?:villa|boat|domain)s/,
          media_type:    /(?:image|tour|pannellum|video|slide)s/,
        } do
        post :reorder, on: :collection
        post :refresh, on: :member
      end

      scope path: "occupancies/:type/:id", constraints: { type: /(villa|boat)s/ } do
        get   "/",                 to: "occupancies#show",          as: :rentable_occupancies
        get   "/collisions/:year", to: "occupancy_collisions#show", as: :occupancy_collisions
        patch "/collisions/:year", to: "occupancy_collisions#update"
      end

      post "markdown/preview" => "markdown_preview#create",
        as: nil

      resources :villa_inquiries, only: %i[new show], path: "inquiries/villas"

      get "stats/:villa_id/:year" => "stats#show"

      resources :sales, only: %i[index]
    end

    namespace :bsp1 do
      resources :transaction_status, only: %i[create]
      resources :pseudocardpans, only: %i[create]
      resources :transactions, only: %i[create] do
        get ":reference_base64/callback" => "transactions#callback", on: :collection, as: :callback
      end
    end

    # für FeWo
    get "ical/:type/:id/:token.ics" => "ical#show",
      constraints: { type: /(villa|boat)s/ },
      as:          :ical,
      format:      false

    get "inquiries/:token/boats" => "boat_inquiries#boats", as: :available_boats
    get "inquiries/:token(.:format)" => "inquiries#show"

    resource :high_seasons, only: :show

    namespace :my_booking_pal do
      post "/notification", to: "notifications#create", as: nil
      post "/reservation",  to: "reservations#create", as: nil
    end

    namespace :paypal do
      scope path: "payments/:inquiry_token", controller: :payments do
        post "/start/:modus", action: :create, as: :payment_start
        get "/cancel", action: :cancel, as: :payment_cancel
        get "/complete", action: :complete, as: :payment_complete
      end
      resources :webhooks, only: :create
      post "/webhook", to: "webhooks#create", as: nil
    end

    get "/progress", to: "progress#show"

    resources :villas, only: %i[show] do
      collection do
        get :geocodes
        get :facets, constraints: { format: :json }
        get :prefetch, constraints: { format: :json }
        get :top_villas, constraints: { format: :json }, path: "top"
        get :with_boat, constraints: { format: :json }, path: "with-boat"
      end
    end
  end

  get "/sitemap.xml", to: "sitemap#index", as: :sitemap, format: false
  root to: "home#index"

  get "/reiseinfo",             to: redirect("/einreisebestimmungen")
  get "/villas-cape-coral",     to: redirect("/villas-cape-coral-mieten")
  get "/villa-cape-coral",      to: redirect("/villas-cape-coral-mieten")
  get "/cape-coral-ferienhaus", to: redirect("/ferienhaus-cape-coral")
  get "/inspiration",           to: redirect("https://instagram.com/intervillasflorida", status: 302)

  Route.inject_routes!(self)

  if defined?(Sidekiq)
    authenticate :user, ->(u) { u.admin? } do
      mount Sidekiq::Web => "/admin/sidekiq"
    end
  end
end
