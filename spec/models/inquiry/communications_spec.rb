require "rails_helper"

RSpec.describe Inquiry do
  let(:inquiry) { create_villa_inquiry.inquiry }
  let(:villa) { inquiry.villa }

  describe "#send_submission_mail" do
    it { expect { inquiry.send_submission_mail }.not_to raise_error }
  end
end
