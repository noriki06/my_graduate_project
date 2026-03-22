# WantsController
# ユーザー自身の「やりたいこと（Want）」の CRUD 操作と、
# 公開 Want の閲覧（public_index / public_wishlist_index / public_show）を担当する。
class WantsController < ApplicationController
  # 全アクションにログインを必須にする
  before_action :authenticate_user!
  # show/edit/update/destroy などの操作対象Wantを事前に取得する
  before_action :set_want, only: %i[show edit update destroy achieve_form achieve toggle_publish]
  # デモユーザーは書き込み系操作を禁止する（check_not_demo は ApplicationController に定義）
  before_action :check_not_demo, only: %i[create update destroy achieve toggle_publish]

  # ===== 自分のWant一覧 =====
  def index
    # ライフゲージの進捗率（誕生日未設定なら0として扱う）
    @life_progress_rate = current_user.life_progress_rate || 0
    # タブパラメータ：nil = やりたいこと / 'achieved' = 達成済み
    @current_tab = params[:tab]

    # ヘッダー統計情報（全Want数・達成数・達成率）
    @total_wants_count    = current_user.wants_count
    @achieved_wants_count = current_user.achieved_count
    @achieve_rate         = current_user.achievement_rate

    # N+1クエリを防ぐために画像関連を includes でまとめて取得する
    base = current_user.wants.includes(picture_attachment: :blob, achieved_image_attachment: :blob)

    # タブによって表示対象を切り替える
    wants =
      if @current_tab == "achieved"
        # 達成タブ：achieved_at がある Want を新しい順に表示
        base.where.not(achieved_at: nil).order(achieved_at: :desc)
      else
        # やりたいことタブ：未達成Want を target_date の近い順に表示
        # target_date が nil のものは末尾に（Arel.sql で NULL を後ろに）
        base.where(achieved_at: nil)
            .order(Arel.sql("target_date IS NULL ASC"), target_date: :asc)
      end

    # time_bucket（年齢帯）ごとにグループ化する（例: "20-29", "30-39"）
    grouped = wants.group_by(&:time_bucket)

    max_age = 89
    birthday = current_user.birthday

    # 現在年齢から89歳までのタイムバケット一覧を生成する（年齢軸の骨格）
    all_buckets =
      if birthday.present?
        current_age = ((Date.current - birthday.to_date).to_i / 365.25).floor
        Want.time_buckets_between(from_age: current_age, to_age: max_age)
      else
        []
      end

    # バケット一覧を空配列で初期化（Wantがないバケットも表示するため）
    @wants_by_bucket = all_buckets.index_with { [] }

    # グループ化されたWantをバケットに割り当てる（nil バケットは除外）
    grouped.each do |bucket, bucket_wants|
      next if bucket.blank?
      @wants_by_bucket[bucket] ||= []
      @wants_by_bucket[bucket].concat(bucket_wants)
    end

    # time_bucket が設定されていないWant（目標日なし・年齢帯未計算）
    @unbucketed_wants = grouped[nil] || []
  end

  # ===== 公開Want一覧：達成済み =====
  # published: true かつ achieved_at がある Want を一覧表示する（ページネーション: 10件/ページ）
  def public_index
    @wants = Want.public_achieved_list
                 .includes(:user, :likes, :comments,
                            achieved_image_attachment: :blob,
                            picture_attachment: :blob)
                 .page(params[:page]).per(10)
  end

  # ===== 公開Want一覧：未達成ウィッシュリスト =====
  # published: true かつ achieved_at が nil の Want を一覧表示する
  def public_wishlist_index
    @wants = Want.public_wishlist
                 .includes(:user, :likes, :comments, picture_attachment: :blob)
                 .page(params[:page]).per(10)
  end

  # ===== 公開Want詳細 =====
  # 達成・未達成どちらの Want も表示可能。
  # public_list スコープで published: true のみに絞り、非公開Wantへの直接アクセスを防ぐ。
  def public_show
    @want = Want.public_list
                .includes(:user, :likes, comments: :user)  # コメントのユーザーも一緒に取得
                .find(params[:id])
    @comment = Comment.new  # コメント投稿フォーム用の空オブジェクト
  end

  # ===== 自分のWant詳細（プライベート） =====
  # 現在は詳細表示専用のビューを使わず index へ遷移することが多い
  def show; end

  # ===== Want 新規作成フォーム =====
  def new
    @want = current_user.wants.new
    @prefill_time_bucket = params[:time_bucket]  # ライフゲージのバケットから直接遷移した場合にプリセット
    @goal_type  = nil   # 目標設定タイプ（"date" or nil）：フォームの初期状態は未選択
    @target_age = nil   # 年齢入力欄の初期値
  end

  # ===== Want 作成 =====
  def create
    @want = current_user.wants.new(want_params)
    # target_age_input はフォームの「〇歳までに」入力欄から取得（仮想属性）
    @want.target_age_input = params[:target_age].to_s
    @target_age = params[:target_age]  # バリデーション失敗時のフォーム再描画用

    if @want.save
      redirect_to wants_path, notice: "登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # ===== Want 編集フォーム =====
  def edit
    # target_date が設定されていれば "date" タイプとして判定（フォームのタブを切り替えるため）
    @goal_type  = @want.target_date.present? ? "date" : nil
    @target_age = nil
  end

  # ===== Want 更新 =====
  def update
    @want.assign_attributes(want_params)
    @want.target_age_input = params[:target_age].to_s  # 年齢入力も反映
    @target_age = params[:target_age]

    if @want.save
      redirect_to wants_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # ===== Want 削除 =====
  def destroy
    @want.destroy
    redirect_to wants_path, notice: "削除しました"
  end

  # ===== 達成記録フォーム表示 =====
  # 達成コメント・達成日・達成画像を入力するフォームを表示する
  def achieve_form; end

  # ===== 達成を保存 =====
  def achieve
    # すでに達成済みかどうかで成功メッセージを切り替える
    already_achieved = @want.achieved?

    # 達成画像が送られてきた場合は Active Storage に添付する
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

  # ===== 公開/非公開 切り替え =====
  # published フラグをトグルして保存する
  # 公開にすると他ユーザーから閲覧・いいね・コメントが可能になる
  def toggle_publish
    @want.update(published: !@want.published?)
    redirect_to wants_path, notice: @want.published? ? "公開しました" : "非公開にしました"
  end

  private

  # current_user のWantのみを対象にすることで他ユーザーのWantへのアクセスを防ぐ
  def set_want
    @want = current_user.wants.find(params[:id])
  end

  # Want フォームで受け付けるパラメータのホワイトリスト
  def want_params
    params.require(:want).permit(:title, :memo, :target_date, :picture, :notify_enabled, :published)
  end

  # 達成フォームで受け付けるパラメータのホワイトリスト
  def achieve_params
    params.require(:want).permit(:achievement_note, :achieved_at, :achieved_image)
  end
end
