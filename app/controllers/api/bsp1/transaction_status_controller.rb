class Api::Bsp1::TransactionStatusController < ApiController
  skip_before_action :verify_authenticity_token
  before_action :verify_net!
  before_action :verify_key!

  PAY_ONE_NETWORK = IPAddr.new "185.60.20.0/24" # IP allow-list
  AUTH_KEY        = Digest::MD5.hexdigest Rails.application.credentials.bsp1.fetch(:key)
  private_constant :PAY_ONE_NETWORK, :AUTH_KEY

  def create
    Bsp1Response.transaction do
      Bsp1Response.create!(bsp1_params) if mode_correct?
    end
  rescue StandardError => err
    raise err if Rails.env.test?

    Sentry.capture_exception(e)
  ensure
    render plain: "TSOK"
  end

  private

  def bsp1_params
    data = params.to_unsafe_h
      .except(:controller, :action)
      .transform_values { |v| v.force_encoding("iso-8859-1").encode("utf-8") }

    {
      txid:       data[:txid],
      txaction:   normalize_txaction(data),
      txtime:     data[:txtime],
      inquiry_id: data[:reference].match(/IV-E?(\d+)-\w\d/)[1],
      price:      data[:price],
      balance:    data[:balance] || 0.to_d,
      data:       data,
    }
  end

  # nur Transaktions-Nachrichten für "live" im Produktiv-System verarbeiten
  # Nachrichten im "test"-Modus können von allen anderen Umgebungen verarbeitet
  # werden
  def mode_correct?
    params[:mode] == (Rails.env.production? ? "live" : "test")
  end

  def verify_net!
    head(:bad_request) unless remote_allowed?(request.remote_ip)
  end

  def remote_allowed?(remote_ip)
    remote_ip == "127.0.0.1" || PAY_ONE_NETWORK.include?(IPAddr.new(remote_ip))
  end

  def verify_key!
    head(:bad_request) if AUTH_KEY != params.require(:key)
  end

  # The current BSP1 version (7.6) responds differntly than the version we've
  # integrated originally. What we expect to be a "paid" and "completed" transaction
  # is now returned differently.
  #
  # See https://docs.payone.com/integration/response-handling/transactionstatus-notification,
  # notably the "List of events" on txaction "appointed":
  #
  # > Via "appointed" you are informed about the successful initiation of the
  # > payment process. This request is affected immediately after the first
  # > successful booking.
  # >
  # > Important note: The new parameter "transaction_status" indicates whether
  # > the event "appointed" is pending or completed.
  #
  # Here, we'll simply re-interpret "appointed" + "completed" as "paid".
  def normalize_txaction(data)
    txaction = data[:txaction]
    return "paid" if txaction == "appointed" && data[:transaction_status] == "completed"

    txaction
  end
end
