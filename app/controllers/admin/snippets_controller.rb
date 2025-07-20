class Admin::SnippetsController < ApplicationController
  include Admin::ControllerExtensions
  layout "admin_bootstrap"
  load_and_authorize_resource Snippet

  expose(:snippets) { Snippet.order(:key) }
  expose(:snippet) do
    if %w[new create].include?(action_name)
      Snippet.new
    else
      Snippet.find(params[:id])
    end
  end

  def new
    respond_to do |format|
      format.html
      format.json { render :json, json: SnippetJSON.new(snippet, context: view_context).as_json }
    end
  end
  alias edit new

  def create
    save_snippet!(:created) { "Text-Schnipsel '#{snippet.title}' erfolgreich erstellt." }
  end

  def update
    save_snippet!(:found) { "Text-Schnipsel '#{snippet.title}' erfolgreich gespeichert." }
  end

  def destroy
    snippet.destroy!
    flash[:notice] = "Der Text-Schnipsel '#{snippet.title}' wurde erfolgreich gelöscht."
    redirect_to admin_snippets_path
  end

  private

  def save_snippet!(success_status)
    snippet.class.transaction do
      snippet.update! permitted_params
    end

    flash[:notice] = yield
    render :json, status: success_status, json: { url: admin_snippets_path }
  rescue ActiveRecord::Rollback, ActiveRecord::RecordInvalid
    render :json, status: :unprocessable_entity, json: { errors: snippet.errors }
  end

  def permitted_params
    params.require(:snippet).permit(
      :key,
      :title,
      :de_content_md,
      :de_content_html,
      :en_content_md,
      :en_content_html,
    )
  end

  class SnippetJSON < VueAdapter
    private

    def collections_for_vue
      nil
    end

    def endpoint_for_vue
      method, url = if new_record?
        ["POST", context.admin_snippets_path(format: :json)]
      else
        ["PATCH", context.admin_snippet_path(id, format: :json)]
      end

      { url: url, method: method }
    end

    def attributes_for_vue
      {
        key:           key,
        title:         title,
        de_content_md: de_content_md,
        en_content_md: en_content_md,
        # rendered client-side via preview
        # de_content_html:  de_content_html,
        # en_content_html:  en_content_html,
      }
    end
  end
  private_constant :SnippetJSON
end
