module CronWorker
  class ForecastUpdate < Base
    every 15.minutes

    def perform_non_staging
      ::WeatherForecast.update!
    end
  end
end
