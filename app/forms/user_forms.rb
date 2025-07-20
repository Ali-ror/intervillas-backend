module UserForms

  class Base < ModelForm
    from_model :user

    delegate :blank_password?, to: :user

    def self.model_name
      User.model_name
    end

    def success_message
      # if #valid? return string for flash[:notice]
    end

    def error_message
      # if not #valid? return string for flash[:error]
    end

    def form_id
      self.class.to_s.demodulize.underscore
    end
  end

  class Basic < Base
    attribute :email, String
    validates :email,
      presence:     true,
      email_format: true
    validate :unique_email

    attribute :access_level, String
    validates :access_level,
      presence: true,
      inclusion: { in: User::ACCESS_LEVEL.keys }

    def success_message
      "Basis-Einstellungen für #{user.email} gespeichert."
    end

  private
    def unique_email
      if u = User.find_by(email: email)
        errors.add :email, :taken if u.id != model.id
      end
    end
  end

  class PasswordReset < Base
    def save
      model.locked_at = nil
      model.send_reset_password_instructions
      true
    end

    def success_message
      "Anleitung zum Password-Reset wurde an #{user.email} versandt."
    end
  end

  class Merge < Base
    attribute :victim_id, Integer
    validate :victim_points_to_user

    def save
      User.transaction do
        # copy permissions
        model.access_bookings   ||= victim.access_bookings
        model.access_inquiries  ||= victim.access_inquiries
        model.admin             ||= victim.admin

        # update relations
        model.contact_ids = (model.contact_ids + victim.contact_ids).uniq

        model.save!
        victim.destroy!
      end
    end

    def victim
      @victim ||= victims.find_by id: victim_id
    end

    def victims
      if new_record?
        User.none
      else
        User.where.not(id: user.id)
      end
    end

    def success_message
      "Benutzer #{victim.email} mit #{user.email} zusammengeführt (und #{victim.email} gelöscht)."
    end

  private

    def victim_points_to_user
      if victim_id.blank? || victim.blank?
        errors.add :victim_id, :invalid
        return
      end

      if victim.id == model.id
        errors.add :victim_id, :victim_is_target
        return
      end
    end
  end

  class Contacts < Base
    attribute :contact_ids, Array[Integer]

    def save
      user.contact_ids = contact_ids
      user.save!
    end
  end

end
