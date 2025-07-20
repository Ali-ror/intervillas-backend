class Admin::DomainsController < ApplicationController
  include Admin::ControllerExtensions
  layout "admin_bootstrap"
  load_and_authorize_resource Domain

  expose(:domains) { Domain.order(:id) }
  expose(:domain) do
    if %w[new create].include?(action_name)
      Domain.new
    else
      Domain.find(params[:id])
    end
  end

  def new
    respond_to do |format|
      format.html
      format.json { render :json, json: DomainJSON.new(domain, context: view_context).as_json }
    end
  end
  alias edit new

  def create
    save_domain!(:created) { "Satelliten-Seite #{domain.name} erfolgreich erstellt." }
  end

  def update
    save_domain!(:found) { "Satelliten-Seite #{domain.name} erfolgreich gespeichert." }
  end

  def destroy
    if domain.default?
      flash[:alert] = "Die Default-Domain kann nicht gelöscht werden."
    else
      domain.destroy!
      flash[:notice] = "Die Satelliten-Seite #{domain.name} wurde erfolgreich gelöscht."
    end
    redirect_to admin_domains_path
  end

  private

  def save_domain!(success_status)
    domain.class.transaction do
      domain.update! permitted_params
    end

    flash[:notice] = yield
    render :json, status: success_status, json: { url: admin_domains_path }
  rescue ActiveRecord::Rollback, ActiveRecord::RecordInvalid
    render :json, status: :unprocessable_entity, json: { errors: domain.errors }
  end

  def permitted_params
    params.require(:domain).permit(*[
      (:name unless domain.default?),
      :brand_name,
      :multilingual,
      :theme,
      :interlink,
      :tracking_code,
      :de_content_md, :de_meta_description, :de_html_title, :de_page_heading,
      :en_content_md, :en_meta_description, :en_html_title, :en_page_heading,
      {
        partials:  [],
        boat_ids:  [],
        page_ids:  [],
        villa_ids: [],
      },
    ].compact)
  end

  class DomainJSON < VueAdapter
    private

    def attributes_for_vue # rubocop:disable Metrics/AbcSize
      return if new_record?

      {
        id:                  id,
        name:                name,
        default:             default?,
        brand_name:          brand_name,
        multilingual:        multilingual?,
        interlink:           interlink?,
        partials:            partials,
        theme:               theme,
        tracking_code:       tracking_code,
        de_content_md:       de_content_md,
        de_meta_description: de_meta_description,
        de_html_title:       de_html_title,
        de_page_heading:     de_page_heading,
        en_content_md:       en_content_md,
        en_meta_description: en_meta_description,
        en_html_title:       en_html_title,
        en_page_heading:     en_page_heading,
        boat_ids:            ids_of(boats.active.visible),
        page_ids:            ids_of(pages),
        villa_ids:           ids_of(villas.active),
        slides_url:          slides_url,
      }
    end

    def endpoint_for_vue
      if new_record?
        { url: context.admin_domains_path(format: :json), method: "POST" }
      else
        { url: context.admin_domain_path(id, format: :json), method: "PATCH" }
      end
    end

    def collections_for_vue
      {
        pages:    page_collection,
        villas:   load_collection(Villa.active),
        boats:    load_collection(Boat.active.visible),
        partials: Domain.valid_partial_names.sort,
        themes:   Domain::THEME_COLORS.keys,
      }
    end

    def ids_of(scope)
      scope.pluck(:id).uniq.sort
    end

    def load_collection(scope)
      scope.order(:id).map { |v|
        { id: v.id, name: v.admin_display_name }
      }
    end

    def page_collection
      Page.includes(:translations, :route).order(:id).map { |pg|
        {
          id:    pg.id,
          title: pg.name(:de),
          name:  pg.route.name,
          path:  "/#{pg.route.path}",
        }
      }
    end

    def slides_url
      return if new_record? # erst speichern

      context.api_admin_media_path \
        rentable_type: __getobj__.class.table_name,
        rentable_id:   id,
        media_type:    "slides",
        format:        :json
    end
  end
  private_constant :DomainJSON
end
