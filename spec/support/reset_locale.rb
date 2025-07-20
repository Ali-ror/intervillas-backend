#
# I18n.locale zurücksetzen. Workaround gegen Controller-Specs, weil:
#
# - Specs laufen nicht in separaten Threads/Prozessen
# - in LocaleExtractor#set_locale (before_action in ApplicationController)
#   wird I18n.locale gesetzt
#
# Wenn Capybara den App-Server startet, nachdem ein nicht-Feature-Spec
# die Locale geändert hat, dann schlagen (fast) alle Feature-Specs fehl.
#
RSpec.configure do |config|
  config.before do
    I18n.locale = I18n.default_locale
  end
end
