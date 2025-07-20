class Admin::PaymentsController < Admin::InquiriesController
  before_action :check_admin!
  before_action :inhibit_editing_paypal_payments!, only: %i[edit update destroy]

  helper_method :ack_payment_forms

  expose(:inquiry) { Inquiry.find params[:inquiry_id] }
  expose(:payments) do
    # Reihenfolge in includes() ist wichtig
    Payment::View.includes(:inquiry, :customer, :messages)
  end

  expose(:payment_form)     { PaymentForm.from_payment payment }
  expose(:ack_payment_form) { ack_payment_forms(payment) }

  expose(:payment) do
    collection = inquiry.payments
    params.key?(:id) ? collection.find(params[:id]) : collection.build
  end

  def index
    respond_to do |format|
      format.html { with_pagination { render :index } }
      format.csv { render csv: payments }
    end
  end

  def create
    payment_form.attributes = payment_params
    if payment_form.valid?
      payment_form.save
      flash[:success] = "Zahlungen gespeichert."
      redirect_to [:edit, :admin, inquiry.terminus, { anchor: "payments" }]
    else
      render :edit
    end
  end

  alias update create

  def destroy
    payment.destroy
    flash[:success] = "Zahlungen gelöscht."
    redirect_to [:edit, :admin, inquiry.terminus, { anchor: "payments" }]
  end

  def overdue
    @payments = payments.overdue

    respond_to do |format|
      format.html { with_pagination { render :index } }
      format.csv { render csv: payments }
    end
  end

  def external
    @payments = payments.external

    respond_to do |format|
      format.html { with_pagination { render :index } }
      format.csv { render csv: payments }
    end
  end

  def unpaid
    @payments = payments.unpaid

    respond_to do |format|
      format.html { with_pagination { render :index } }
      format.csv { render csv: payments }
    end
  end

  class CsvHash < SimpleDelegator
    def to_comma(*)
      values.map(&:to_comma).join
    end
  end

  def balance
    @balance = Currency::CURRENCIES.each_with_object(CsvHash.new({})) { |curr, acc|
      acc[curr] = Balance.new params[:year].to_i, curr
    }

    respond_to do |format|
      format.html
      format.csv { render csv: @balance }
    end
  end

  def acked
    @payments = payments.acked_downpayments

    respond_to do |format|
      format.html { with_pagination { render :index } }
      format.csv { render csv: payments }
    end
  end

  private

  def payment_params
    params.require(:payment).permit(%i[paid_on sum scope comment])
  end

  def with_pagination
    @payments = payments.paginate(per_page: 30, page: (params[:page] || 1))
    yield
  end

  def ack_payment_forms(payment_or_booking)
    BookingForms::PaymentAcknowledge.from payment_or_booking
  end

  def inhibit_editing_paypal_payments!
    return head(:forbidden) if payment.scope == "paypal"
  end
end
