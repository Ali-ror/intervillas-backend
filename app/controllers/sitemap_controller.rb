class SitemapController < ApplicationController
  def index
    @villas = with_current_domain(Villa).active.includes(:route)

    # Page#17 ist hier explizip ausgenommen aufgrund von
    # https://git.digineo.de/intervillas/support/-/issues/409
    @pages  = with_current_domain(Page).includes(:route).where(noindex: false).where.not(id: 17)

    render layout: false, formats: [:xml]
  end
end
