# == Schema Information
#
# Table name: pages
#
#  content       :text
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  modified_at   :datetime
#  name          :string
#  noindex       :boolean          default(FALSE), not null
#  published_at  :datetime
#  template_path :string
#  updated_at    :datetime         not null
#

class Page < ApplicationRecord
  translates :name, :content
  include Digineo::I18n
  default_scope { includes(:translations) }

  include HasRoute
  has_route controller: "admin/routes"
  include DomainScoped

  def to_s
    name
  end

  # Seiten sollten nicht gelöscht werden, wenn die Route einen Namen hat
  def route_with_name?
    route.name?
  end
end
