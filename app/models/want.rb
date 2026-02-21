class Want < ApplicationRecord
  belongs_to :user

  validates :title, presence: true

  TIME_BUCKET_SPAN = 5
  before_validation :set_time_bucket, if: :should_set_time_bucket?

  scope :for_list, -> {
    order(Arel.sql("achieved_at IS NOT NULL ASC"))
      .order(achieved_at: :desc, created_at: :desc)
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

  # 例）27 -> "25-29"
  def self.time_bucket_for_age(age, span: TIME_BUCKET_SPAN)
    return nil if age.nil?

    start_age = (age / span) * span
    end_age = start_age + (span - 1)
    "#{start_age}-#{end_age}"
  end

  private

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
end
