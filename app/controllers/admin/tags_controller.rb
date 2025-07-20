class Admin::TagsController < ApplicationController
  include Admin::ControllerExtensions
  authorize_resource :tag
  layout "admin_bootstrap"

  expose(:tags)       { Tag.includes(:category, :translations).order(:category_id, :name) }
  expose(:tags_form)  { tags.map { |tag| TagForm.from_tag tag } }
  expose(:categories) { Category.pluck(:name, :id).map { |cat, id| [t(cat, scope: "category"), id] }.sort }

  expose(:single_tag)       { tags.find params[:id] }
  expose(:single_tag_form)  { TagForm.from_tag single_tag }

  def update
    if single_tag_form.process(tag_params)
      single_tag_form.save
      if request.xhr?
        render json: { status: "ok" }, status: :ok
      else
        redirect_to admin_tags_path, notice: "Tag aktualisiert"
      end
      return
    end

    if request.xhr?
      render json: { status: "error", errors: single_tag_form.errors.messages }, status: :unprocessable_entity
    else
      render :edit
    end
  end

  private

  def tag_params
    params.require(:tag).permit(*%i[
      category_id
      filterable
      de_description de_name_one de_name_other
      en_description en_name_one en_name_other
    ] + [{
      amenity_ids: [],
    }])
  end
end
