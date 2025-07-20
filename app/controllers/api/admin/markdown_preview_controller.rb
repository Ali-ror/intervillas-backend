class Api::Admin::MarkdownPreviewController < ApplicationController
  include Admin::ControllerExtensions
  wrap_parameters false
  layout          false

  expose(:markdown) { permitted_params[:content].presence }

  def create
    head :unprocessable_entity and return if markdown.blank?
    render json: { body: RenderKramdown.new(markdown).to_html }
  end

  private

  def permitted_params
    params.permit(:content)
  end
end
