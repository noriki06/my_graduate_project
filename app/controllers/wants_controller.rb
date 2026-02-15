class WantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_want, only: %i[show edit update destroy achieve_form achieve]

  def index
    @life_progress_rate = current_user.life_progress_rate || 0
    @wants = current_user.wants.order(achieved_at: :asc, created_at: :desc).page(params[:page]).per(10)
  end

  def show; end

  def new
    @want = current_user.wants.new
  end

  def create
    @want = current_user.wants.new(want_params)

    if @want.save
      redirect_to wants_path, notice: "登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @want.update(want_params)
      redirect_to wants_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @want.destroy
    redirect_to wants_path, notice: "削除しました"
  end

  def achieve_form
  end

  def achieve
    already_achieved = @want.achieved?

    if @want.achieve(
        achievement_note: params.dig(:want, :achievement_note),
        achieved_at_input: params.dig(:want, :achieved_at),
        now: Time.current
      )
      notice = already_achieved ? "思い出メモを更新しました！" : "達成を記録しました！"
      redirect_to wants_path, notice: notice
    else
      render :achieve_form, status: :unprocessable_entity
    end
  end

  private

  def set_want
    @want = current_user.wants.find(params[:id])
  end

  def want_params
    params.require(:want).permit(:title, :memo, :target_date)
  end
end
