module HighSeasonsHelper
  def timespan(dates)
    dates.map { |date|
      I18n.l date, format: :timespan
    }.join(" bis ")
  end
end
