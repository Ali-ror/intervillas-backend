require "rails_helper"

RSpec.describe Api::ContactsController do
  describe "on POST to :create" do
    let(:name)         { "test name" }
    let(:email)        { "foo@bar.org" }
    let(:text)         { "foo bar baz" }
    let(:current_page) { "https://www.intervillas-florida.com/kontakt" }

    before do
      post :create, params: {
        contact_request: {
          name:         name,
          email:        email,
          text:         text,
          current_page: current_page,
        }.compact,
      }
    end

    it { is_expected.to respond_with :success }

    it "returns nothing" do
      expect(response.body).to be_empty
    end

    it "delivers an email" do
      mail = ActionMailer::Base.deliveries.first
      expect(mail.to).to eq ["info@intervillas-florida.com"]
      expect(mail.from).to eq ["noreply@intervillas-florida.com"]
      expect(mail.subject).to eq "Intervilla Kontaktformular Anfrage"
      expect(mail.reply_to).to eq [email]
    end

    it "contains content" do
      mail = ActionMailer::Base.deliveries.first
      body = Capybara.string mail.body.encoded
      expect(body).to have_content "Nachricht: #{text}"
      expect(body).to have_content "Seite: #{current_page}"
      expect(body).to have_content "Villa: —"
    end

    context "incomplete params" do
      let(:email) { nil }

      it { is_expected.to respond_with :unprocessable_entity }

      it "returns errors" do
        data = JSON.parse(response.body)
        expect(data["email"]).to eq ["muss ausgefüllt werden"]
      end
    end
  end
end
