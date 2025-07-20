module Api
  module Admin
    class OccupancyCollisionsController < ApplicationController
      include ::Admin::ControllerExtensions
      before_action :check_admin!

      expose(:rentable_type) do
        raise ActiveRecord::RecordNotFound unless %w[villas boats].include?(params[:type])

        params[:type]
      end

      expose(:rentable) do
        current_user.send(rentable_type).find params[:id]
      end

      expose(:blockings) do
        y = params[:year]
        rentable.blockings.clashes("#{y}-01-01", "#{y}-12-31")
      end

      def show
        # render jbuilder template
      end

      def update
        ids = params.require(:blocking).permit(ids: []).fetch(:ids, [])
        Blocking.where(id: ids).find_each(&:ignore!) if ids.present?

        render "show"
      end
    end
  end
end
