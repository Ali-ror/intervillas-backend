class Admin::SettingsController < ApplicationController
  include Admin::ControllerExtensions

  authorize_resource :setting

  layout "admin_bootstrap"

  expose(:setting) { Setting::COERCABLES.fetch(params[:id]) }

  expose(:current_settings) do
    Setting::COERCABLES.map { |name, coercable|
      [name, coercable.get]
    }
  end

  def update
    setting.set params[:value]
    render json: { error: false, message: "Einstellung gespeichert" }
  rescue KeyError
    render json: { error: true, message: "Einstellung nicht gefunden" }, status: :not_found
  end
end
