class Admin::MessagesController < ApplicationController
  include Admin::ControllerExtensions

  load_and_authorize_resource Message

  # Booking-/Billing-Instanz, dessen Empfängern eine Mail geschickt werden soll
  expose(:context_object) do
    if params.key?(:billing_id)
      Billing.find params[:billing_id]
    elsif params.key?(:booking_id)
      Inquiry.find params[:booking_id] # unschön
    elsif params.key?(:inquiry_id)
      Inquiry.find params[:inquiry_id]
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  expose(:message) do
    type = params.require(:message).require(:type)
    MessageFactory.for(context_object).build(type)
  end

  expose(:message_form) { MessageForm.from_message message }
  expose(:preview)      { message.preview }

  expose(:current_template) { params[:template].presence }
  expose(:current_status)   { params[:status].presence }

  expose(:message_templates) do
    Message.distinct.pluck(:template)
      .map { |template| [template, t(template, scope: "messages.templates")] }
      .sort_by(&:second)
  end

  expose(:messages) do
    scope = Message.includes(:recipient, :inquiry, :booking)
      .order(created_at: :desc)
      .paginate(page: params[:page] || 1, per_page: 100)

    case current_status
    when "sent"
      scope.where.not(sent_at: nil)
    when "transit"
      scope.where(sent_at: nil).where.not(status: nil)
    when "unknown"
      scope.where(sent_at: nil, status: nil)
    else
      current_template ? scope.where(template: current_template) : scope
    end
  end

  def index
    render layout: "admin_bootstrap"
  end

  def create
    message_form.attributes = message_params
    message_form.save

    flash["success"] = "Nachricht wird in Kürze versendet"
    redirect_back fallback_location: admin_messages_path
  end

  def live_preview
    message.tap { |m| m.text = message_params[:text] }
    with_recipient_locale { render :preview, layout: false }
  end

  # displays stored email, and falls back to preview if none found
  def show
    @message  = Message.where(inquiry_id: params[:inquiry_id]).find(params[:id])
    @delivery = @message.deliveries.last
    return render layout: false if @delivery

    with_recipient_locale { render :preview, layout: false }
  end

  def resend
    with_message_returning { message.resend! }
  end

  private

  def message_params
    params.require(:message).permit(:text)
  end

  def with_message_returning
    @message = Message.where(inquiry_id: params[:inquiry_id]).find(params[:id])

    yield

    if request.xhr?
      render partial: "messages/message", layout: false
    else
      redirect_to [:edit, :admin, message.booking || message.inquiry, { anchor: "communication" }]
    end
  end

  def with_recipient_locale(&block)
    I18n.with_locale @message.recipient.locale, &block
  end
end
