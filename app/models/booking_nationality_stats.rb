# == Schema Information
#
# Table name: bookings
#
#  ack_downpayment :boolean          default(FALSE), not null
#  booked_on       :datetime
#  exchange_rate   :decimal(, )      not null
#  pseudocardpan   :string
#  summary_on      :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  inquiry_id      :integer          not null
#  travel_mail_id  :integer
#
# Indexes
#
#  fk__bookings_inquiry_id       (inquiry_id)
#  fk__bookings_travel_mail_id   (travel_mail_id)
#  index_bookings_on_inquiry_id  (inquiry_id) UNIQUE
#
# Foreign Keys
#
#  fk_bookings_inquiry_id      (inquiry_id => inquiries.id) ON DELETE => cascade
#  fk_bookings_travel_mail_id  (travel_mail_id => messages.id) ON DELETE => cascade
#
class BookingNationalityStats < ApplicationRecord
  self.table_name = "bookings"

  QUERY = <<~SQL.squish.freeze
    select  distinct case k.country
            when ''    then null
            when 'USA' then 'US'
            else k.country
            end                     as country
          , count(*)                as n
    from bookings b
    inner join inquiries i on i.id = b.inquiry_id
    inner join customers k on k.id = i.customer_id
    group by 1 /* country */
    order by 2 /* n */ desc
  SQL

  scope :nationalities, -> { find_by_sql(QUERY) }

  def share_in_year(year)
    @share_in_year ||= cachable { |y|
      if counts[y].zero?
        0
      else
        val = Booking.in_year(y).joins(:customer).where(customers: { country: country }).count
        val.to_d / counts[y]
      end
    }

    @share_in_year[year]
  end

  def readonly?
    true
  end

  private

  def counts
    @counts ||= cachable { |y| Booking.in_year(y).count }
  end

  def cachable
    Hash.new { |h, k| h[k] = yield k }
  end
end
