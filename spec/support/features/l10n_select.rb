RSpec.configure do |config|
  # disable localization banner (this solves an issue with differences in
  # browser and application locale)
  config.before(:example, type: :feature) do
    allow_any_instance_of(ApplicationController).to receive(:show_localization_select?).and_return(false)
  end
end
