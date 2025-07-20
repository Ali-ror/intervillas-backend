class ApplicationMailer < ActionMailer::Base
  include EmailStorage
  include Exposer

  helper PriceHelper, SalutationHelper, MailerHelper, CorporateHelper
  helper_method :signature_template

  default from: "info@intervillas-florida.com"
  layout "mailer"

  private

  def signature_template
    corp = if defined?(inquiry) && inquiry.present?
      inquiry.for_corporate?
    elsif defined?(booking) && booking.present?
      booking.inquiry&.for_corporate?
    else
      # XXX: can't access `intervillas_corp?` here!?
      DateTime.current >= Rails.configuration.x.corporate_switch_date
    end

    corp ? "corp" : "gmbh"
  end

  def subdomain
    @subdomain ||= [locale_domain, env_domain].compact.join(".")
  end

  def locale_domain
    I18n.locale == :en ? "en" : "www"
  end

  def env_domain
    if Rails.env.test?
      "self"
    elsif Rails.env.staging?
      "staging"
    end
  end

  def inquiry_subject(key, villa_name: nil)
    inquiry_number = if defined?(inquiry)
      inquiry.number
    elsif defined?(@inquiry)
      @inquiry.number
    else
      raise ArgumentError, "missing inquiry"
    end

    I18n.t key, inquiry_number: inquiry_number, villa_name: villa_name
  end
end
