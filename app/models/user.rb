# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  access_bookings        :boolean          default(FALSE), not null
#  access_inquiries       :boolean          default(FALSE), not null
#  admin                  :boolean          default(FALSE), not null
#  consumed_timestep      :integer
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  otp_backup_codes       :string           is an Array
#  otp_required_for_login :boolean          default(FALSE), not null
#  otp_secret             :string
#  password_expires_at    :datetime
#  previous_passwords     :string           default([]), not null, is an Array
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0)
#  unlock_token           :string
#  villa_owner            :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class User < ApplicationRecord
  devise(
    :two_factor_authenticatable,
    :two_factor_backupable,
    :recoverable,
    :trackable,
    :validatable,
    :lockable,
    :timeoutable,
    otp_number_of_backup_codes: 4,
  )

  include Users::AccessLevels
  include Users::Passwords
  include Users::SecondFactor
  include DomainScoped

  has_many :messages, as: :recipient
  has_and_belongs_to_many :contacts

  include Users::Cables

  scope :ordered, -> { order(:email) }

  def villas
    return Villa.all if admin?
    return Villa.none if new_record?

    rentable_query Villa
  end

  def boats
    return Boat.all if admin?
    return Boat.none if new_record?

    rentable_query Boat
  end

  def villa_ids
    villas.pluck(:id)
  end

  def boat_ids
    boats.pluck(:id)
  end

  def blockings
    # include rentable, allow villa_id/boat_id to be null
    scope = Blocking
      .joins("LEFT OUTER JOIN villas ON villas.id = blockings.villa_id")
      .joins("LEFT OUTER JOIN boats ON boats.id = blockings.boat_id")

    return scope         if admin?
    return Blocking.none if new_record?

    # include owner/manager for rentable, allow owner_id/manager_id to be null
    scope = scope
      .joins("LEFT OUTER JOIN contacts cvo ON cvo.id = villas.owner_id")
      .joins("LEFT OUTER JOIN contacts cvm ON cvm.id = villas.manager_id")
      .joins("LEFT OUTER JOIN contacts cbo ON cbo.id = boats.owner_id")
      .joins("LEFT OUTER JOIN contacts cbm ON cbm.id = boats.manager_id")

    # join owner/manager with users (via join table)
    scope = scope
      .joins("INNER JOIN contacts_users cu ON cu.contact_id IN (cvo.id, cvm.id, cbo.id, cbm.id)")
      .joins("INNER JOIN users ON users.id = cu.user_id")

    scope.where(users: { id: id })
  end

  def booking_year_range
    curr_year = Time.current.year
    {
      true  => (2011..curr_year + 6),
      false => [curr_year, curr_year + 1],
    }[admin?]
  end

  def allowed_booking_states
    whitelist = %w[booked commission_received full_payment_received]
    whitelist - disallowed_booking_states
  end

  def disallowed_booking_states
    admin? ? [] : %w[submitted other_booked]
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  protected

  def email_required?
    true
  end

  def password_required?
    persisted? && super
  end

  private

  def rentable_query(klass)
    q = %w[owner_id manager_id].map { |c|
      format %{"%s"."%s" in (:cids)}, klass.table_name, c
    }.join " or "

    klass.where q, cids: contact_ids
  end
end
