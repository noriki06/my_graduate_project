class WantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_want, only: [ :show, :edit, :update, :destroy ]

  def index
    @wants = current_user.wants.order(created_at: :desc)
  end

  def show
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

  def edit
  end

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

  private

  # 本人のWantしか取得できない（＝本人のみ操作可能）
  def set_want
    @want = current_user.wants.find(params[:id])
  end

  def want_params
    params.require(:want).permit(:title, :memo, :deadline)
  end
end
