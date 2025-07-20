module Admin
  module Devise
    class UnlocksController < ::Devise::UnlocksController
      layout "admin_bootstrap_devise"
    end
  end
end
