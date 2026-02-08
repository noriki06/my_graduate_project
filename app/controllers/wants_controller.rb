class WantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_want, only: [ :show, :edit, :update, :destroy, :achieve_form, :achieve ]

  def index
    @life_progress_rate = current_user.life_progress_rate
    @wants = current_user.wants.order(achieved_at: :asc, created_at: :desc).page(params[:page]).per(10)
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

  # GET /wants/:id/achieve_form
  # GET /wants/:id/achieve_form
  def achieve_form
    # 達成済みでも「達成メモ編集」として開きたいのでリダイレクトしない
  end

  # PATCH /wants/:id/achieve
  def achieve
    if @want.achieved?
      # すでに達成済み：メモ（と任意の達成日入力）があれば更新
      if @want.update(achieve_params.compact_blank)
        redirect_to wants_path, notice: "思い出メモを更新しました！"
      else
        render :achieve_form, status: :unprocessable_entity
      end
      return
    end

    # 未達成：達成として記録（達成日は未入力なら今日）
    if @want.update(achieve_params.merge(achieved_at: achieved_at_from_params))
      redirect_to wants_path, notice: "達成を記録しました！"
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

  def achieve_params
    params.fetch(:want, {}).permit(:achievement_note, :achieved_at)
  end

  def achieved_at_from_params
    input = params.dig(:want, :achieved_at)
    input.present? ? Time.zone.parse(input).end_of_day : Time.current
  end
end
