if Rails.application.config.action_controller.asset_host.present?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(
        "localhost:3000",
        "127.0.0.1:3000",
        "[::1]:3000",
        /.*\.local\.digineo\.de:\d+\z/,
        /(www|en)\.(staging\.)?intervillas-florida\.com/,
        /(www|en)\.(staging\.)?cape-coral-ferienhaeuser\.com/,
        /(www|en)\.(staging\.)?villa-capecoral-mieten\.de/,
      )

      resource "*", methods: %i[get post put patch delete]
    end
  end
end
