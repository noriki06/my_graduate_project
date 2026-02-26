class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_want

  def create
    @want.likes.find_or_create_by(user: current_user)
    redirect_back fallback_location: public_want_path(@want)
  end

  def destroy
    like = @want.likes.find_by(user: current_user)
    like&.destroy
    redirect_back fallback_location: public_want_path(@want)
  end

  private

  def set_want
    @want = Want.public_list.find(params[:id])
  end
end
