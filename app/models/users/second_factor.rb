module Users
  module SecondFactor
    extend ActiveSupport::Concern

    OTPError       = Class.new(StandardError)
    OTPNotPrepared = Class.new(OTPError)
    OTPInvalid     = Class.new(OTPError)

    # Users with access to customer data must use a 2nd factor.
    def role_requires_otp?
      admin?
    end

    # Setup OTP secrets for the current user. OTP is not yet required
    # for login (use #enable_otp! for that). Returns a provisioning
    # URL for the end-user to consume (usually presented as QR code
    # and scanned into an authehticator app).
    #
    # @return [String] Provisioning URL
    def prepare_otp!
      update! otp_secret: self.class.generate_otp_secret
      otp_provisioning_uri
    end

    def otp_provisioning_uri
      super email, issuer: "Intervilla Florida"
    end

    def otp_provisioning_qrcode(...)
      Qrcode.new(otp_provisioning_uri).to_svg(...)
    end

    # Given the user was setup for OTP (see #prepare_otp!), and given a
    # valid OTP code, this enables OTP after login. Returns a list of backup
    # codes for safe-keeping on the user side.
    #
    # If `self` wasn't prepared, a OTPNotPrepared will be thrown. If the
    # given `code` is not a valid OTP, a OTPInvalid will be thrown.
    #
    # @param [String] code A (currently valid) OTP.
    # @return [Array<String>] Backup codes.
    def enable_otp!(code)
      raise OTPNotPrepared unless otp_secret?
      raise OTPInvalid     unless validate_and_consume_otp!(code)

      generate_otp_backup_codes!.tap do
        self.otp_required_for_login = true
        save!
      end
    end

    # Removes OTP material from the user and disables the OTP request on
    # login. Must be confirmed with an OTP when the second factor is active,
    # otherwise this will throw an OTPInvalid error.
    #
    # @param [String] code A (currently valid) OTP. Ignored when OTP is only
    #   prepared, but not enabled yet.
    # @return [void]
    def disable_otp!(code = nil)
      if otp_secret? && otp_required_for_login?
        ok = validate_and_consume_otp!(code) || invalidate_otp_backup_code!(code)
        raise OTPInvalid unless ok
      end

      update!(
        otp_secret:             nil,
        otp_required_for_login: false,
        otp_backup_codes:       [],
      )
      nil
    end
  end
end
