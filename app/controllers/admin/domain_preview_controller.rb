class Admin::DomainPreviewController < ApplicationController
  before_action :set_meta_tags

  expose(:special)            { Special.first }
  expose(:usps)               { Usp.all I18n.locale }
  expose(:reviews)            { with_current_domain(Review).best_ratings }
  expose(:last_minute_villas) { villas_for_special || [] }

  def show
    render "home/index", layout: "application"
  end

  private

  def current_domain
    @current_domain ||= Domain.includes(:translations).find(params[:id])
  end

  def villas_for_special
    return unless special

    with_current_domain(special.villas)
      .reorder(Arel.sql("random()"))
      .available_with_limit(3)
  end

  def set_meta_tags
    @route = current_domain.pseudo_route
  end
end
