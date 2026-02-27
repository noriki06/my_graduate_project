class AiSuggestionsController < ApplicationController
  before_action :authenticate_user!

  def create
    @want = select_want
    if @want
      suggestion_text = AiSuggestionService.call(@want, current_user)
      @daily = current_user.daily_action_suggestions.create!(
        want: @want,
        suggested_action: suggestion_text,
        suggested_on: Date.current
      )
    end
  end

  private

  def select_want
    wants = current_user.wants.where(notify_enabled: true, achieved_at: nil)
                        .includes(:daily_action_suggestions)
    return nil if wants.empty?

    wants.sort_by { |w| [ -(urgency_score(w) + recency_score(w)), w.created_at ] }.first
  end

  def urgency_score(want)
    return 0 unless want.target_date

    days = (want.target_date - Date.current).to_i
    return 100 if days <= 7
    return 50  if days <= 30
    10
  end

  def recency_score(want)
    last = want.daily_action_suggestions.maximum(:suggested_on)
    return 50 unless last

    [ (Date.current - last).to_i * 5, 50 ].min
  end
end
