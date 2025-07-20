module SignInHelper
  def sign_in_admin
    authenticate_user create(:user, :with_password, :with_second_factor, admin: true)
  end

  def authenticate_user(user)
    sign_in user, scope: :user
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end
end

module CapybaraSignInHelper
  def sign_in_admin
    admin = create(:user, :with_password, :with_second_factor, admin: true)
    sign_in admin, scope: :user
  end

  def sign_in_manager
    user    = create(:user, :with_password)
    contact = create(:contact)
    user.contacts << contact

    create :villa, :bookable, manager: contact

    sign_in user, scope: :user
    visit admin_root_path

    contact
  end
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers,   type: :controller
  config.include SignInHelper,                      type: :controller

  config.include Devise::Test::IntegrationHelpers,  type: :feature
  config.include CapybaraSignInHelper,              type: :feature
end
