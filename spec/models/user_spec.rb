require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "nameが空ならinvalid" do
      user = build(:user, name: "")
      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
    end

    it "notification_frequencyがdaily/weekly以外ならinvalid" do
      user = build(:user, notification_frequency: "hourly")
      expect(user).not_to be_valid
    end

    it "notification_hourが24以上ならinvalid" do
      user = build(:user, notification_hour: 24)
      expect(user).not_to be_valid
    end

    it "notification_hourが0-23ならvalid" do
      user = build(:user, notification_hour: 0)
      expect(user).to be_valid
    end

    it "notification_day_of_weekが7以上ならinvalid" do
      user = build(:user, notification_day_of_week: 7)
      expect(user).not_to be_valid
    end

    it "birthdayが未来日ならinvalid" do
      user = build(:user, birthday: Date.tomorrow)
      expect(user).not_to be_valid
      expect(user.errors[:birthday]).to be_present
    end

    it "birthdayが今日以前ならvalid" do
      user = build(:user, birthday: Date.today)
      expect(user).to be_valid
    end
  end

  describe "#age" do
    it "誕生日から年齢を計算する" do
      birthday = Date.new(Date.current.year - 30, Date.current.month, Date.current.day)
      user = build(:user, birthday: birthday)
      expect(user.age).to eq(30)
    end

    it "birthdayがnilならnil" do
      user = build(:user, birthday: nil)
      expect(user.age).to be_nil
    end
  end

  describe "#lived_days" do
    it "生まれてからの日数を返す" do
      birthday = 10.years.ago.to_date
      user = build(:user, birthday: birthday)
      expect(user.lived_days).to eq((Date.current - birthday).to_i)
    end

    it "birthdayがnilならnil" do
      user = build(:user, birthday: nil)
      expect(user.lived_days).to be_nil
    end
  end

  describe "#life_progress_rate" do
    it "0〜100の間の値を返す" do
      user = build(:user, birthday: 30.years.ago.to_date)
      expect(user.life_progress_rate).to be_between(0, 100)
    end

    it "birthdayがnilならnil" do
      user = build(:user, birthday: nil)
      expect(user.life_progress_rate).to be_nil
    end
  end

  describe "#life_end_date" do
    it "誕生日から84年後を返す" do
      user = build(:user, birthday: Date.new(1990, 6, 15))
      expect(user.life_end_date).to eq(Date.new(2074, 6, 15))
    end

    it "birthdayがnilならnil" do
      user = build(:user, birthday: nil)
      expect(user.life_end_date).to be_nil
    end
  end

  describe "#remaining_life_days" do
    it "残り日数が0以上の整数を返す" do
      user = build(:user, birthday: 30.years.ago.to_date)
      expect(user.remaining_life_days).to be >= 0
    end

    it "birthdayがnilなら0" do
      user = build(:user, birthday: nil)
      expect(user.remaining_life_days).to eq(0)
    end
  end

  describe "#line_linked?" do
    it "line_user_idがあればtrue" do
      user = build(:user, line_user_id: "U123456")
      expect(user.line_linked?).to be true
    end

    it "line_user_idがなければfalse" do
      user = build(:user, line_user_id: nil)
      expect(user.line_linked?).to be false
    end
  end
end
