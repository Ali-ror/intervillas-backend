module DateRangePickerHelper
  def date_range_picker
    @date_range_picker ||= ::DateRangePickerHelper::DSL.new(self)
  end

  class DSL < SimpleDelegator
    JS_INTL_SHORT_MONTH_NAMES = {
      de: [nil] + %w[Jan Feb Mär Apr Mai Jun Jul Aug Sep Okt Nov Dez],
      en: [nil] + %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec],
    }.freeze

    attr_reader :locale

    # FIXME: Dies nimmt an, dass I18n.locale im Test und im app_server
    #        identisch sind. Die Alternative via evaluate_script das
    #        lang-Attribut vom <body> auszulesen ist mir hier aber zu
    #        teuer (die allermeisten Tests laufen eh mit :de-locale).
    def initialize(context, locale = :de)
      super context
      @locale = locale
    end

    def wait
      # init abwarten
      expect(page).not_to have_content "Bitte warten, Daten werden geladen"
      yield if block_given?
    end

    def within_widget
      wait

      click_on_until(".date-range-picker-wrapper") do
        has_css?(".date-range-picker", wait: 0.1)
      end

      within ".date-range-picker" do
        yield self
      end
      true # Return-Value von within ist nun obsolet.
    end

    def within_wrapper(&block)
      within ".date-range-picker-wrapper", &block
    end

    # Setzt den date-range-ricker auf die übergebenen Daten
    #
    # select_dates(*dates)
    #   @param [Array<Date, String>] dates
    def select_dates(*dates, confirm: true)
      within_widget do
        dates.each { |date| click_date date }
        click_on "OK" if confirm
      end
    end

    def within_first_calendar(&block)
      within first(".date-range-picker-calendar"), &block
    end

    def click_date(date)
      date  = date.to_date unless date.is_a?(Date)
      month = JS_INTL_SHORT_MONTH_NAMES.dig(locale, date.month)

      # ggf. gar nicht notwendig
      within_first_calendar { select date.year.to_s, from: "year" }
      within_first_calendar { select month, from: "month" }

      within_first_calendar { click_on date.day.to_s }
    end
  end
end

RSpec.configure do |config|
  config.include DateRangePickerHelper
end
