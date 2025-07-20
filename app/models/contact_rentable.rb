# == Schema Information
#
# Table name: contacts_rentables_view
#
#  active        :boolean
#  manager_id    :integer
#  name          :string
#  owner_id      :integer
#  rentable_id   :integer          primary key
#  rentable_type :text             primary key
#

class ContactRentable < ApplicationRecord
  self.table_name = "contacts_rentables_view"
  self.primary_key = [:rentable_type, :rentable_id]

  belongs_to :rentable, polymorphic: true
  belongs_to :owner,    class_name: "Contact"
  belongs_to :manager,  class_name: "Contact"

protected

  def readonly?
    true
  end
end
