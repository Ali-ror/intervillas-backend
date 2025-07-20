#
# Leert vor jedem Test-Durchlauf die log/test.log. Verhalten kann über
# die Umgebungsvariable TRUNCATE_LOGS gesteuert werden (z.B. permanent
# in der .env.test):
#
#     TRUNCATE_LOGS=suite     - einmal vor dem rake/rspec-Durchlauf
#     TRUNCATE_LOGS=example   - vor jedem Example (it/its/scenario)
#     TRUNCATE_LOGS=context   - vor jedem Context (context/describe)
#
# Ich musste vor Kurzem eine 20G-Logdatei löschen, weil ich das mal ein
# paar Tage nicht manuell gemacht hab... Dies macht das nun automatisch.
#       —Dominik
#

hook = case ENV["TRUNCATE_LOGS"]
when "suite"   then :suite
when "example" then :example
when "context" then :context
else                false
end

RSpec.configure do |config|
  if hook
    config.before(hook) do
      Rails.root.join("log/test.log").truncate(0)
    end
  end

  if ENV["KEEP_MESSAGES"] != "1"
    # remove stored messages
    config.before do
      message_dir = Rails.root.join("tmp/data/messages")
      message_dir.rmtree if message_dir.exist?
    end
  end
end
