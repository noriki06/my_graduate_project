class WantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_want, only: %i[show edit update destroy achieve_form achieve]

  def index
    @life_progress_rate = current_user.life_progress_rate || 0

    wants = current_user.wants.for_list
    grouped = wants.group_by(&:time_bucket)

    current_age = ((Date.current - current_user.birthday.to_date).to_i / 365.25).floor
    max_age = 89

    all_buckets = Want.time_buckets_between(from_age: current_age, to_age: max_age)

    @wants_by_bucket = all_buckets.index_with { [] }

    grouped.each do |bucket, bucket_wants|
      next if bucket.blank?
      @wants_by_bucket[bucket] ||= []
      @wants_by_bucket[bucket].concat(bucket_wants)
    end

    @unbucketed_wants = grouped[nil] || []
  end

  def show; end

  def new
    @want = current_user.wants.new
    @prefill_time_bucket = params[:time_bucket]
  end

  def create
    @want = current_user.wants.new(want_params)
    apply_target_age!(@want)

    if @want.save
      redirect_to wants_path, notice: "登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @want.assign_attributes(want_params)
    apply_target_age!(@want)

    if @want.save
      redirect_to wants_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @want.destroy
    redirect_to wants_path, notice: "削除しました"
  end

  def achieve_form; end

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

  # 🔥 ここが今回の追加部分
  def apply_target_age!(want)
    age_str = params[:target_age].presence
    return if age_str.blank?
    return if current_user.birthday.blank?

    age = age_str.to_i
    return if age <= 0

    # 誕生日 + age年
    want.target_date = current_user.birthday.to_date + age.years
  end
end
