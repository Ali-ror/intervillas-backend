module Users
  module Passwords
    extend ActiveSupport::Concern

    MAX_PASSWORD_AGE                    = 90.days.freeze
    PASSWORD_EXPIRY_WARNING_PERIOD      = 3.days.freeze # prior to expiry
    PASSWORD_EXPIRY_SOFT_WARNING_PERIOD = 7.days.freeze # prior to expiry

    MAX_PREVIOUS_PASSWORDS_TO_KEEP = 4

    included do
      before_save :update_password_expiry
      before_update :capture_previous_passwords, if: :will_save_change_to_encrypted_password?
      validate :validate_previous_passwords
    end

    def password_expired?(time = Time.current)
      password_expires_at.nil? || password_expires_at <= time
    end

    def password_expiry_warning?(time = Time.current)
      password_expired?(time) || warn_range.cover?(time)
    end

    def password_expiry_soft_warning?(time = Time.current)
      return false unless password_expires_at?

      soft_warn_range.cover?(time)
    end

    private

    def soft_warn_range
      @soft_warn_range ||= Range.new(
        password_expires_at - PASSWORD_EXPIRY_SOFT_WARNING_PERIOD,
        password_expires_at - PASSWORD_EXPIRY_WARNING_PERIOD,
        true, # exclude end
      )
    end

    def warn_range
      @warn_range ||= Range.new(
        password_expires_at - PASSWORD_EXPIRY_WARNING_PERIOD,
        password_expires_at,
        true, # exclude end
      )
    end

    # called as before_save hook: updates password_expires_at iff. the password
    # was changed (but not password_expires_at itself)
    def update_password_expiry
      if (new_record? || will_save_change_to_encrypted_password?) && !will_save_change_to_password_expires_at?
        self.password_expires_at = MAX_PASSWORD_AGE.from_now.change(usec: 0)
      end
    end

    def validate_previous_passwords
      return unless will_save_change_to_encrypted_password?
      return unless reused_previous_password?

      errors.add(:password, :previously_used)
    end

    def reused_previous_password?
      return false if password.blank? # password change bypassed `password=` setter

      current_password_list.any? { |pw|
        self.class.new(encrypted_password: pw).valid_password?(password)
      }
    end

    def capture_previous_passwords
      return if previous_passwords.include?(encrypted_password_was)

      self.previous_passwords = current_password_list
    end

    def current_password_list
      [encrypted_password_was, *previous_passwords]
        .compact_blank
        .uniq
        .take(MAX_PREVIOUS_PASSWORDS_TO_KEEP)
    end
  end
end
