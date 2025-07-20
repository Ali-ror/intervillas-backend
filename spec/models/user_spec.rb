require "rails_helper"
require "cancan/matchers"

RSpec.describe User do
  it { is_expected.to have_db_column "email" }
  it { is_expected.to validate_presence_of "email" }

  it { is_expected.to have_and_belong_to_many :contacts }

  describe "abilities", vcr: { cassette_name: "villa/geocode" } do
    subject(:ability) { Ability.new(user) }

    let(:user) { nil }

    context "as guest" do
      { # should
        Villa   => %i[read gallery geocodes search gap],
        Inquiry => %i[create update],
        Booking => %i[create],
      }.each do |object, actions|
        actions.each do |action|
          it { is_expected.to be_able_to(action, object) }
        end
      end

      { # should not
        Page    => %i[index update destroy],
        Inquiry => %i[destroy],
        Villa   => %i[create destroy],
        Booking => %i[index update destroy],
      }.each do |object, actions|
        actions.each do |action|
          it { is_expected.not_to be_able_to(action, object) }
        end
      end
    end

    describe "admin abilities", vcr: { cassette_name: "villa/geocode" } do
      subject(:ability) { AdminAbility.new(user) }

      context "unprivileged (as guest)" do
        it { is_expected.to be_able_to(:read, create(:page)) }
      end

      context "privileged" do
        let(:contact)       { create :contact }
        let(:owned_villa)   { create :villa, :bookable, :with_inquiries, manager: nil,     owner: contact }
        let(:managed_villa) { create :villa, :bookable, :with_inquiries, manager: contact, owner: nil }
        let(:other_villa)   { create :villa, :bookable, :with_inquiries, manager: nil,     owner: nil }

        before do
          user.contacts << contact
        end

        context "(as manager)" do
          let(:user) { create :user, :with_password }

          describe "accessing owned/managed villas" do
            let(:villas) { [owned_villa, managed_villa] }

            it "allows to shows them" do
              villas.each { |v| is_expected.to be_able_to(:show, v) }
            end

            it "allows bookings listings" do
              villas.each do |villa|
                villa.bookings.each { |b| is_expected.to be_able_to(:index, b) }
              end
            end

            it "allows calendar view" do
              villas.each { |v| is_expected.to be_able_to(:calendar, v) }
            end

            it "rejects grid view" do
              villas.each { |v| is_expected.not_to be_able_to(:grid, v) }
            end
          end

          describe "accessing other villas" do
            %i[show calendar grid].each do |action|
              it { is_expected.not_to be_able_to(action, other_villa) }
            end

            it "not possible for their bookings" do
              other_villa.bookings.each { |b| is_expected.not_to be_able_to(:index, b) }
            end
          end

          %i[edit update create].each do |action|
            it { is_expected.not_to be_able_to(action, Villa) }
          end
        end

        context "(as admin)" do
          let(:user)   { create :user, :with_password, :with_second_factor, admin: true }
          let(:villas) { [owned_villa, managed_villa, other_villa] }

          it "can show all villas" do
            villas.each { |v| is_expected.to be_able_to(:show, v) }
          end

          %i[edit update create].each do |action|
            it { is_expected.to be_able_to(action, Villa) }
          end
        end
      end
    end
  end

  describe "password policy" do
    subject(:user) { create :user, password: "vielzueinfach" }

    def expect_expiry(user, expired: false, warning: false, soft_warning: false)
      expect(user.password_expired?).to             be expired
      expect(user.password_expiry_warning?).to      be warning
      expect(user.password_expiry_soft_warning?).to be soft_warning
    end

    it "has multiple stages of expiry" do
      expect(user.password_expires_at).to be_within(1.second).of(90.days.from_now)
      expect_expiry(user)

      cases = { # duration from now => [expired?, warn?, soft_warn?]
        83.days - 1.second => [false, false, false], # < 83d ago
        83.days            => [false, false, true],  # = 83d ago
        83.days + 1.second => [false, false, true],  # > 83d ago
        87.days - 1.second => [false, false, true],  # < 87d ago
        87.days            => [false, true, false],  # = 87d ago
        87.days + 1.second => [false, true, false],  # > 87d ago
        90.days - 1.second => [false, true, false],  # < 90d ago
        90.days            => [true,  true, false],  # = 90d ago
        90.days + 1.second => [true,  true, false],  # > 90d ago
      }
      expect(cases.keys.size).to eq 9 # i.e. distinct, non-null, non-neighboring base values

      cases.each do |offset, (expired, warning, soft_warning)|
        travel_to(offset.from_now) do
          expect_expiry user,
            expired:      expired,
            warning:      warning,
            soft_warning: soft_warning
        end
      end
    end

    it "does not allow password reuse" do
      user.update password: "vielzueinfach"
      expect(user).not_to be_valid
      expect(user).to have_error(:previously_used, on: :password)
    end

    it "allows password reuse after 4 rotations" do
      (1..4).each do |i|
        user.update password: "foobar!#{i}"
        expect(user).to be_valid
      end

      user.update password: "vielzueinfach"
      expect(user).to be_valid

      user.update password: "foobar!2"
      expect(user).not_to be_valid
    end
  end
end
