RSpec.configure do |config|
  %i[feature controller request].each do |type|
    config.before(:example, type: type) do
      create :domain, :default_domain unless Domain.exists?(default: true)
    end
  end
end
