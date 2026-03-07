class AiSuggestionsController < ApplicationController
  before_action :authenticate_user!

  def create
    @want = Want.select_for_suggestion(current_user)
    if @want
      suggestion_text = AiSuggestionService.call(@want, current_user)
      @daily = current_user.daily_action_suggestions.create!(
        want: @want,
        suggested_action: suggestion_text,
        suggested_on: Date.current
      )
    else
      @no_wants_at_all = current_user.wants.empty?
    end
  end
end
