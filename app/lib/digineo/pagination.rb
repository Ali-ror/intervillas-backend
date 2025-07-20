# encoding: UTF-8

module Digineo::Pagination
  private

  def collection
    if paginate?
      finder_params = { per_page: per_page, page: params[:page] || 1 }
      @collection ||= cancan_induced_end_of_association_chain(super).paginate(finder_params)
    else
      @collection ||= cancan_induced_end_of_association_chain(super)
    end
  end

  def per_page
    20
  end

  # override in controller; to disable return false
  def paginate?
    true
  end

  def cancan_induced_end_of_association_chain(collection_relation)
    if respond_to? :current_ability
      collection_relation.accessible_by(current_ability)
    else
      collection_relation
    end
  end
end
