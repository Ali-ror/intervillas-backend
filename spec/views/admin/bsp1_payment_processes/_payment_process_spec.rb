require "rails_helper"

RSpec.describe "admin/bsp1_payment_processes/_payment_process.html.haml" do
  it "displays amount" do
    bsp1_payment_process = create(:bsp1_payment_process)

    render partial: "admin/bsp1_payment_processes/payment_process", locals: { payment_process: bsp1_payment_process }

    expect(rendered).to include("€ 12'345,00") # amount
    expect(rendered).to include("€ 12,00") # handling_fee
  end
end
