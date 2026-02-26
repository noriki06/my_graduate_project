require "rails_helper"

RSpec.describe Want, type: :model do
  describe "validations" do
    it "titleが空ならinvalid" do
      want = build(:want, title: "")
      expect(want).not_to be_valid
      expect(want.errors[:title]).to be_present
    end

    it "titleがあればvalid" do
      want = build(:want)
      expect(want).to be_valid
    end
  end

  describe "#achieved?" do
    it "achieved_atがあればtrue" do
      want = build(:want, achieved_at: Time.current)
      expect(want.achieved?).to be true
    end

    it "achieved_atがなければfalse" do
      want = build(:want, achieved_at: nil)
      expect(want.achieved?).to be false
    end
  end

  describe "scopes" do
    let!(:published_achieved) { create(:want, published: true, achieved_at: 1.day.ago) }
    let!(:published_wishlist)  { create(:want, published: true, achieved_at: nil) }
    let!(:private_want)        { create(:want, published: false, achieved_at: nil) }

    describe ".public_list" do
      it "published=trueのwantのみ返す" do
        result = Want.public_list
        expect(result).to include(published_achieved, published_wishlist)
        expect(result).not_to include(private_want)
      end
    end

    describe ".public_achieved_list" do
      it "達成済みの公開wantのみ返す" do
        result = Want.public_achieved_list
        expect(result).to include(published_achieved)
        expect(result).not_to include(published_wishlist, private_want)
      end
    end

    describe ".public_wishlist" do
      it "未達成の公開wantのみ返す" do
        result = Want.public_wishlist
        expect(result).to include(published_wishlist)
        expect(result).not_to include(published_achieved, private_want)
      end
    end
  end

  describe ".time_bucket_for_age" do
    it "27歳 → '20-29'" do
      expect(Want.time_bucket_for_age(27)).to eq("20-29")
    end

    it "30歳 → '30-39'" do
      expect(Want.time_bucket_for_age(30)).to eq("30-39")
    end

    it "0歳 → '0-9'" do
      expect(Want.time_bucket_for_age(0)).to eq("0-9")
    end

    it "ageがnilならnil" do
      expect(Want.time_bucket_for_age(nil)).to be_nil
    end
  end

  describe "#achieve" do
    let(:want) { create(:want, achieved_at: nil, achievement_note: nil) }

    it "未達成wantを達成に更新する" do
      want.achieve(achievement_note: "やり遂げた！")
      expect(want.reload.achieved?).to be true
      expect(want.achievement_note).to eq("やり遂げた！")
    end

    it "achieved_at_inputを指定すると日時がセットされる" do
      date = Date.new(2025, 1, 1)
      want.achieve(achievement_note: "完了", achieved_at_input: date)
      expect(want.reload.achieved_at.to_date).to eq(date)
    end

    it "達成済みwantのノートを更新できる" do
      want.update!(achieved_at: 1.week.ago)
      want.achieve(achievement_note: "追記しました")
      expect(want.reload.achievement_note).to eq("追記しました")
    end
  end
end
