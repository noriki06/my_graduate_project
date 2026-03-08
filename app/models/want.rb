class Want < ApplicationRecord
  belongs_to :user
  has_one_attached :picture
  has_one_attached :achieved_image
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :daily_action_suggestions, dependent: :destroy

  attr_accessor :target_age_input

  validates :title, presence: true
  validate :picture_size
  validate :achieved_image_size

  TIME_BUCKET_SPAN = 10
  before_validation :apply_target_age_input, if: -> { !target_age_input.nil? }
  before_validation :set_time_bucket, if: :should_set_time_bucket?
  after_save :ensure_single_notify_enabled, if: :notify_enabled?

  scope :for_list, -> {
    includes(picture_attachment: :blob, achieved_image_attachment: :blob)
      .order(Arel.sql("achieved_at IS NOT NULL ASC"))
      .order(achieved_at: :desc, created_at: :desc)
  }

  # 公開されたWantのみを取得するスコープ（達成問わず）
  scope :public_list, -> {
    where(published: true)
  }

  # 達成済み公開Want
  scope :public_achieved_list, -> {
    where(published: true).where.not(achieved_at: nil)
      .order(created_at: :desc)
  }

  # 未達成公開Want（ウィッシュリスト）
  scope :public_wishlist, -> {
    where(published: true, achieved_at: nil)
      .order(created_at: :desc)
  }

  def achieved?
    achieved_at.present?
  end

  def achieve(achievement_note:, achieved_at_input: nil, now: Time.current)
    attrs = { achievement_note: achievement_note }

    if achieved?
      attrs[:achieved_at] = parse_achieved_at(achieved_at_input, now) if achieved_at_input.present?
      update(attrs.compact_blank)
    else
      attrs[:achieved_at] = parse_achieved_at(achieved_at_input, now)
      update(attrs.compact_blank)
    end
  end

  def self.time_bucket_for_age(age, span: TIME_BUCKET_SPAN)
    return nil if age.nil?

    start_age = (age / span) * span
    end_age   = start_age + (span - 1)
    "#{start_age}-#{end_age}"
  end

  # 例）27 -> "25-29"
  def self.time_buckets_between(from_age:, to_age:, span: TIME_BUCKET_SPAN)
    return [] if from_age.nil? || to_age.nil?
    return [] if to_age < from_age

    start = (from_age / span) * span
    last  = (to_age / span) * span

    (start..last).step(span).map do |s|
      "#{s}-#{s + (span - 1)}"
    end
  end

  # AI提案対象のWantを選定するロジック（urgency + recency スコアリング）
  def self.select_for_suggestion(user)
    wants = user.wants.where(notify_enabled: true, achieved_at: nil)
                      .includes(:daily_action_suggestions)

    if wants.empty?
      wants = user.wants.where(achieved_at: nil).includes(:daily_action_suggestions)
      return nil if wants.empty?
      return wants.sample
    end

    wants.sort_by { |w| [ -(urgency_score(w) + recency_score(w)), w.created_at ] }.first
  end

  private

  def self.urgency_score(want)
    return 0 unless want.target_date

    days = (want.target_date - Date.current).to_i
    return 100 if days <= 7
    return 50  if days <= 30
    10
  end
  private_class_method :urgency_score

  def self.recency_score(want)
    last = want.daily_action_suggestions.maximum(:suggested_on)
    return 50 unless last

    [ (Date.current - last).to_i * 5, 50 ].min
  end
  private_class_method :recency_score

  def apply_target_age_input
    age_str = target_age_input.to_s.strip

    if age_str.present?
      unless age_str.match?(/\A\d+\z/)
        errors.add(:base, "年齢は半角数字で入力してください")
        return
      end
      age = age_str.to_i
      unless age.between?(1, 120)
        errors.add(:base, "年齢は 1〜120 の範囲で入力してください")
        return
      end
      if user.blank? || user.birthday.blank?
        errors.add(:base, "プロフィールに誕生日を設定してください（年齢から目標日を計算します）")
        return
      end
      self.target_date = user.birthday.to_date + age.years

    elsif target_date.present?
      if target_date < Date.current
        errors.add(:base, "目標日に過去の日付は設定できません")
      end

    else
      self.target_date = nil
    end
  end

  def ensure_single_notify_enabled
    user.wants.where.not(id: id).update_all(notify_enabled: false)
  end

  def set_time_bucket
    return if target_date.blank?
    return if user.blank? || user.birthday.blank?

    age = ((target_date.to_date - user.birthday.to_date).to_i / 365.25).floor
    self.time_bucket = self.class.time_bucket_for_age(age)
  end

  def should_set_time_bucket?
    time_bucket.blank? || will_save_change_to_target_date? || will_save_change_to_user_id?
  end

  def parse_achieved_at(input, now)
    return now.end_of_day if input.blank?

    time =
      case input
      when Time then input
      when Date then input.in_time_zone
      else
        begin
          Time.zone.parse(input.to_s)
        rescue ArgumentError, TypeError
          nil
        end
      end

    (time || now).end_of_day
  end

  def picture_size
    return unless picture.attached?
    return if picture.blob.byte_size <= 3.megabytes

    errors.add(:picture, "は3MB以下にしてください")
  end

  def achieved_image_size
    return unless achieved_image.attached?
    return if achieved_image.blob.byte_size <= 3.megabytes

    errors.add(:achieved_image, "は3MB以下にしてください")
  end
end
