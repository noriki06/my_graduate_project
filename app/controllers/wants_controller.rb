class WantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_want, only: %i[show edit update destroy achieve_form achieve toggle_publish]

  def index
    @life_progress_rate = current_user.life_progress_rate || 0
    @current_tab = params[:tab] # nil = やりたいこと / 'achieved' = 達成


    @total_wants_count    = current_user.wants_count
    @achieved_wants_count = current_user.achieved_count
    @achieve_rate         = current_user.achievement_rate

    all_wants = current_user.wants.for_list

    # サブタブで表示対象を切り替え
    wants =
      if @current_tab == "achieved"
        all_wants.select(&:achieved?)
      else
        all_wants.reject(&:achieved?)
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

  # 公開Want一覧：達成済み（ログイン必須）
  def public_index
    @wants = Want.public_achieved_list
                 .includes(:user, :likes, :comments, achieved_image_attachment: :blob)
                 .page(params[:page]).per(10)
  end

  # 公開Want一覧：未達成ウィッシュリスト（ログイン必須）
  def public_wishlist_index
    @wants = Want.public_wishlist
                 .includes(:user, :likes, :comments, picture_attachment: :blob)
                 .page(params[:page]).per(10)
  end

  # 公開Want詳細（達成・未達成両対応、ログイン必須）
  def public_show
    @want = Want.public_list
                .includes(:user, :likes, comments: :user)
                .find(params[:id])
    @comment = Comment.new
  end

  def show; end

  def new
    @want = current_user.wants.new
    @prefill_time_bucket = params[:time_bucket]
    @goal_type  = nil   # 2択のどちらも初期選択しない
    @target_age = nil
  end

  def create
    @want = current_user.wants.new(want_params)
    @target_age = params[:target_age]

    apply_target_age!(@want)

    if @want.errors.none? && @want.save
      current_user.wants.where.not(id: @want.id).update_all(notify_enabled: false) if @want.notify_enabled?
      redirect_to wants_path, notice: "登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @goal_type  = @want.target_date.present? ? "date" : nil
    @target_age = nil
  end

  def update
    @want.assign_attributes(want_params)
    @target_age = params[:target_age]

    apply_target_age!(@want)

    if @want.errors.none? && @want.save
      current_user.wants.where.not(id: @want.id).update_all(notify_enabled: false) if @want.notify_enabled?
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

  # 公開/非公開切り替え
  def toggle_publish
    if @want.user == current_user
      @want.update(published: !@want.published?)
      redirect_to wants_path, notice: @want.published? ? "公開しました" : "非公開にしました"
    else
      redirect_to wants_path, alert: "権限がありません"
    end
  end

  private

  def set_want
    @want = current_user.wants.find(params[:id])
  end

  def want_params
    params.require(:want).permit(:title, :memo, :target_date, :picture, :notify_enabled, :published)
  end

  def achieve_params
    params.require(:want).permit(:achievement_note, :achieved_at, :achieved_image)
  end

  # 年齢 or 日付のどちらかが入力されていれば target_date をセット
  # 年齢が入力されていれば優先、なければ日付、どちらも空なら目標なし（nil）
  def apply_target_age!(want)
    age_str = params[:target_age].presence

    if age_str.present?
      unless age_str.match?(/\A\d+\z/)
        want.errors.add(:base, "年齢は半角数字で入力してください")
        return
      end
      age = age_str.to_i
      unless age.between?(1, 120)
        want.errors.add(:base, "年齢は 1〜120 の範囲で入力してください")
        return
      end
      if current_user.birthday.blank?
        want.errors.add(:base, "プロフィールに誕生日を設定してください（年齢から目標日を計算します）")
        return
      end
      want.target_date = current_user.birthday.to_date + age.years

    elsif want.target_date.present?
      if want.target_date < Date.current
        want.errors.add(:base, "目標日に過去の日付は設定できません")
      end

    else
      want.target_date = nil
    end
  end
end
