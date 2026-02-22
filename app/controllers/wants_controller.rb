class WantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_want, only: %i[show edit update destroy achieve_form achieve]

  def index
    @life_progress_rate = current_user.life_progress_rate || 0

    wants = current_user.wants.for_list

    # ✅ 追加：達成率（思い出の達成率）
    @total_wants_count = wants.size
    @achieved_wants_count = wants.count(&:achieved?)
    @achieve_rate =
      if @total_wants_count.zero?
        0.0
      else
        (@achieved_wants_count.to_f / @total_wants_count * 100).clamp(0, 100)
      end

    grouped = wants.group_by(&:time_bucket)

    max_age = 89
    birthday = current_user.birthday

    all_buckets =
      if birthday.present?
        current_age = ((Date.current - birthday.to_date).to_i / 365.25).floor
        Want.time_buckets_between(from_age: current_age, to_age: max_age)
      else
        []
      end

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

    if achieve_params[:achieved_image].present?
      @want.achieved_image.attach(achieve_params[:achieved_image])
    end

    if @want.achieve(
      achievement_note: achieve_params[:achievement_note],
      achieved_at_input: achieve_params[:achieved_at],
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
    params.require(:want).permit(:title, :memo, :target_date, :picture)
  end

  def achieve_params
    params.require(:want).permit(:achievement_note, :achieved_at, :achieved_image)
  end

  # 年齢が入力されたときだけ target_date を計算してセットする
  # （日付入力がある場合はそれを尊重する）
  def apply_target_age!(want)
    age_str = params[:target_age].presence
    return if age_str.blank?
    return if want.target_date.present? # ← 日付入力が優先
    return if current_user.birthday.blank?

    age = age_str.to_i
    return if age <= 0

    want.target_date = current_user.birthday.to_date + age.years
  end
end
