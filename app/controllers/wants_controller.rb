class WantsController < ApplicationController
  before_action :authenticate_user!

  def index
    @wants = current_user.wants.order(created_at: :desc)
  end
end
