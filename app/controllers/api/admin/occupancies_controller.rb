module Api
  module Admin
    class OccupanciesController < ApplicationController
      include ::Admin::ControllerExtensions
      before_action :check_admin!

      memoize(:rentable_type, private: true) do
        raise ActiveRecord::RecordNotFound unless %w[villas boats].include?(params[:type])

        params[:type]
      end

      memoize(:rentable, private: true) do
        current_user.send(rentable_type).find params[:id]
      end

      # GET /api/admin/occupancies/:type/:id(.json)(?except=:inquiry_id)
      def show
        exporter = OccupancyExporter.from(rentable)
        exporter.except_inquiry!(params[:except]) if params[:except].present?
        render json: exporter.admin_export
      end
    end
  end
end
