class Bsp1::Authorization < Bsp1::Request
  attr_accessor :reference, :last_name, :country, :successurl, :wallettype, :pseudocardpan, :errorurl, :backurl, :currency

  validates_presence_of :reference, :last_name, :country, :successurl, :pseudocardpan

  def build_params
    bsp1_params(
      pseudocardpan: pseudocardpan,
      request:       "authorization",
      clearingtype:  "cc",
      reference:     reference,
      lastname:      last_name,
      country:       country,
      successurl:    successurl,
      errorurl:      errorurl,
      backurl:       backurl,
      currency:      currency,
    )
  end

  def self.from_inquiry(inquiry, reference)
    payable  = inquiry.terminus || inquiry.reservation
    customer = inquiry.customer
    ref_64   = Base64.urlsafe_encode64(reference)

    new.tap { |auth|
      auth.pseudocardpan = payable.pseudocardpan
      auth.reference     = reference
      auth.last_name     = customer.last_name
      auth.country       = customer.country
      auth.language      = customer.locale
      auth.currency      = inquiry.currency
      url_helpers        = Rails.application.routes.url_helpers
      token              = inquiry.token

      auth.successurl = url_helpers.callback_api_bsp1_transactions_url(
        reference_base64: ref_64,
        host:             callback_host,
        result:           "success",
      )

      auth.errorurl = url_helpers.callback_api_bsp1_transactions_url(
        reference_base64: ref_64,
        host:             callback_host,
        result:           "error",
      )

      auth.backurl = url_helpers.callback_api_bsp1_transactions_url(
        reference_base64: ref_64,
        host:             callback_host,
        result:           "cancel",
      )
    }
  end
end
