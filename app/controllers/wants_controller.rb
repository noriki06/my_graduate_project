class WantsController < ApplicationController
  before_action :authenticate_user!

  def index
    @wants = current_user.wants.order(created_at: :desc)
  end

  def new
    @want = Want.new
  end

  def create
    @want = current_user.wants.new(want_params)

    if @want.save
      redirect_to wants_path, notice: "登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def want_params
    params.require(:want).permit(:title, :memo, :deadline)
  end
end
