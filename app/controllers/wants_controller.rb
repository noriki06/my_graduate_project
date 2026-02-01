class WantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_want, only: [:show, :edit, :update, :destroy, :achieve]

  def index
    @wants = current_user.wants.order(achieved_at: :asc, created_at: :desc)
  end

  def show; end

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

  def achieve
    # 達成済みはGETでもPATCHでも弾く（URL直叩き対策）
    return redirect_to @want, notice: "すでに達成済みです" if @want.achieved?

    # 入力画面（GET）は表示するだけ
    return if request.get?

    # 保存（PATCH）
    if @want.update(achieve_params.merge(achieved_at: achieved_at_from_params))
      redirect_to @want, notice: "達成を記録しました！"
    else
      render :achieve, status: :unprocessable_entity
    end
  end

  private

  def set_want
    @want = current_user.wants.find(params[:id])
  end

  def want_params
    params.require(:want).permit(:title, :memo, :target_date)
  end

  def achieve_params
    params.require(:want).permit(:achievement_note, :achieved_at)
  end

  def achieved_at_from_params
    input = params.dig(:want, :achieved_at)
    input.present? ? Time.zone.parse(input).end_of_day : Time.current
  end
end
