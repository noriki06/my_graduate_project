require "rails_helper"

RSpec.describe Want, type: :model do
  describe "#achieved?" do
    it "achieved_atがあればtrue" do
      want = build(:want, achieved_at: Time.current)
      expect(want.achieved?).to be true
    end
  end
end
