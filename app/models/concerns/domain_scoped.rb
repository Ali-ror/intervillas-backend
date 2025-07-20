module DomainScoped
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :domains
    scope :on_domain, ->(d) {
      if Domain === d
        joins(:domains).where(domains: { id: d.id })
      else # String
        joins(:domains).where(domains: { name: d })
      end
    }
  end
end
