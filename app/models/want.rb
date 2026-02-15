class Want < ApplicationRecord
  belongs_to :user

  validates :title, presence: true

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
      if achieved_at_input.present?
        attrs[:achieved_at] = parse_achieved_at(achieved_at_input, now)
      end
      update(attrs.compact_blank)
    else
      attrs[:achieved_at] = parse_achieved_at(achieved_at_input, now)
      update(attrs.compact_blank)
    end
  end

  private

  def parse_achieved_at(input, now)
    return now.end_of_day if input.blank?

    time =
      case input
      when Time
        input
      when Date
        input.in_time_zone
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
