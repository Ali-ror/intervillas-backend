# Such- und Filter-Funktionen, die primär dazu dienen, die Such- und Filter-
# Logik aus den Models zu holen, wenn diese nicht anderweitig benutzt wird.
#
# Werden hauptsächlich in Kombination mit SearchForms::* genutzt, können aber
# auch eigenständig verwendet werden.
module Search
  # for conveniance
  def self.customer(user, query:, villa_id: nil, boat_id: nil, **)
    return [] if query.blank? || query.to_s.length < 3

    Customer.new(user, query.to_s, villa_id, boat_id).results
  end

  # for conveniance
  def self.review(villa_id: nil, inquiry_id: nil, filter: nil)
    Review.new(villa_id, inquiry_id, filter).results
  end

  # Findet einen Kunden anhand seines Namens/seiner E-Mail-Adresse und liefert
  # eine nach Datum sortierte Liste von Anfragen bzw. Buchungen
  class Customer < Struct.new(:user, :query, :villa_id, :boat_id) # rubocop:disable Style/StructInheritance
    def results
      q = "%#{query.downcase.gsub('%', '')}%"
      user.admin? ? admin_results(q) : non_admin_results(q)
    end

    private

    NON_ADMIN_QUERY = <<~SQL.squish.freeze
      lower(customers.first_name) || ' ' ||
      lower(customers.last_name) LIKE :q
    SQL

    ADMIN_QUERY = <<~SQL.squish.freeze
      lower(customers.email) || ' ' ||
      #{NON_ADMIN_QUERY}
    SQL

    RENTABLES_SCOPE = <<~SQL.squish.freeze
      (
        villas.id in (select id from villas where owner_id IN (:u) or manager_id in (:u)) or
        boats.id  in (select id from boats  where owner_id IN (:u) or manager_id in (:u))
      )
    SQL

    def admin_results(query)
      restrict_to_rentables ::Inquiry
        .includes(:customer, :booking, :villa, :boat)
        .references(*[:customer, (:villa if villa_id), (:boat if boat_id)].compact)
        .reorder(created_at: :desc)
        .where(ADMIN_QUERY, q: query)
    end

    def non_admin_results(query)
      restrict_to_rentables ::Inquiry
        .includes(:customer, :booking, :villa, :boat)
        .references(:customer, :villa, :boat)
        .reorder(created_at: :desc)
        .where(RENTABLES_SCOPE, u: user.contact_ids)
        .where(NON_ADMIN_QUERY, q: query)
    end

    def restrict_to_rentables(scope)
      scope = scope.where(villas: { id: villa_id }) if villa_id
      scope = scope.where(boats:  { id: boat_id })  if boat_id
      scope
    end
  end

  class Review < Struct.new(:villa_id, :inquiry_id, :filter_name) # rubocop:disable Style/StructInheritance
    FILTER_PROCS = {
      "publishable" => ->(query) { query.unpublished.with_text.with_rating },
      "complete"    => ->(query) { query.complete },
      "incomplete"  => ->(query) { query.where INCOMPLETE_QUERY },
      "nostars"     => ->(query) { query.with_text.where(rating: [nil, ""]) },
      "archived"    => ->(query) { query.where.not(deleted_at: nil) },
    }.freeze

    INCOMPLETE_QUERY = <<~SQL.squish.freeze
      text    IS NULL OR text = '' OR
      name    IS NULL OR name = '' OR
      rating  IS NULL
    SQL

    FILTER = FILTER_PROCS.keys.freeze

    def results
      return ::Review.where(inquiry_id: inquiry_id) if inquiry_id

      query = ::Review.includes(:villa, inquiry: :villa_inquiry)
      query = query.undeleted unless filter_name == "archived"
      query = query.where(villa_id: villa_id) if villa_id

      if (fproc = FILTER_PROCS.fetch(filter_name, nil))
        query = fproc.call(query)
      end

      query
    end
  end
end
