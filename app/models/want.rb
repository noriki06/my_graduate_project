# Want モデル
# ユーザーの「やりたいこと」1件を表すメインモデル。
# 未達成（achieved_at: nil）と達成済み（achieved_at: 日時あり）の2つの状態を持つ。
# 公開（published: true）にすると他のユーザーから閲覧・いいね・コメントができる。
class Want < ApplicationRecord
  # ===== アソシエーション =====
  belongs_to :user                                    # 投稿したユーザー（必須）
  has_one_attached :picture                           # やりたいことのイメージ画像（Active Storage）
  has_one_attached :achieved_image                    # 達成時に添付する記念画像
  has_many :likes, dependent: :destroy                # いいね（ユーザーが削除されたら連鎖削除）
  has_many :comments, dependent: :destroy             # コメント（同上）
  has_many :daily_action_suggestions, dependent: :destroy # AI提案履歴（同上）

  # ===== 仮想属性 =====
  # フォームから「〇歳までに」という入力を受け取るための仮想属性
  # DB には保存されず、before_validation で target_date に変換される
  attr_accessor :target_age_input

  # ===== バリデーション =====
  validates :title, presence: true  # タイトルは必須
  validate :picture_size            # 画像サイズを3MB以下に制限
  validate :achieved_image_size     # 達成画像も同様に3MB以下

  # ===== 定数 =====
  # 年齢を「25-34」のような10歳刻みの範囲（タイムバケット）に丸めるための幅
  TIME_BUCKET_SPAN = 10

  # ===== コールバック =====
  # target_age_input が入力されていれば target_date に変換（保存前に実行）
  before_validation :apply_target_age_input, if: -> { !target_age_input.nil? }
  # target_date が変わったときなどに time_bucket を再計算する
  before_validation :set_time_bucket, if: :should_set_time_bucket?
  # notify_enabled: true のWantは1件のみ許可するため、他のWantを false にリセット
  after_save :ensure_single_notify_enabled, if: :notify_enabled?

  # ===== スコープ =====

  # 自分のWant一覧表示用：
  # - 画像をN+1クエリなしで取得（includes）
  # - 未達成を上に、達成済みを下に表示（achieved_at IS NOT NULL ASC）
  # - 達成済みは新しい順、未達成も新しい順
  scope :for_list, -> {
    includes(picture_attachment: :blob, achieved_image_attachment: :blob)
      .order(Arel.sql("achieved_at IS NOT NULL ASC"))
      .order(achieved_at: :desc, created_at: :desc)
  }

  # 公開されたWantのみを取得するスコープ（達成問わず）
  # いいね・コメント操作の前にこのスコープで対象を絞り、非公開Wantへのアクセスを防ぐ
  scope :public_list, -> {
    where(published: true)
  }

  # 達成済み公開Want（「みんなの達成」一覧用）
  # 達成日があり published: true のもの、新しい順
  scope :public_achieved_list, -> {
    where(published: true).where.not(achieved_at: nil)
      .order(created_at: :desc)
  }

  # 未達成公開Want（「みんなのウィッシュリスト」一覧用）
  # achieved_at が nil で published: true のもの、新しい順
  scope :public_wishlist, -> {
    where(published: true, achieved_at: nil)
      .order(created_at: :desc)
  }

  # ===== インスタンスメソッド =====

  # 達成済みかどうかを判定する（achieved_at に日時が入っていれば達成済み）
  def achieved?
    achieved_at.present?
  end

  # 達成を記録または更新するメソッド
  # - 初回達成：achieved_at と achievement_note を保存
  # - 再編集（達成済みの場合）：achievement_note と必要なら achieved_at も更新
  # achieved_at_input が空なら現在時刻の end_of_day（日の終わり）を使う
  def achieve(achievement_note:, achieved_at_input: nil, now: Time.current)
    attrs = { achievement_note: achievement_note }

    if achieved?
      # すでに達成済みの場合：日付が指定されていれば更新する
      attrs[:achieved_at] = parse_achieved_at(achieved_at_input, now) if achieved_at_input.present?
      update(attrs.compact_blank)
    else
      # 初回達成：日付を必ずセット（入力なければ今日の終わり）
      attrs[:achieved_at] = parse_achieved_at(achieved_at_input, now)
      update(attrs.compact_blank)
    end
  end

  # ===== クラスメソッド =====

  # 年齢（整数）を10歳刻みのタイムバケット文字列に変換する
  # 例）27 -> "20-29"、35 -> "30-39"
  def self.time_bucket_for_age(age, span: TIME_BUCKET_SPAN)
    return nil if age.nil?

    start_age = (age / span) * span       # 例: 27 / 10 * 10 = 20
    end_age   = start_age + (span - 1)    # 例: 20 + 9 = 29
    "#{start_age}-#{end_age}"
  end

  # from_age〜to_age の範囲に含まれるタイムバケットをすべて列挙する
  # 例）27 -> "25-29" のように span 刻みの範囲を生成
  # wants/index でライフゲージの年齢軸を表示するために使う
  def self.time_buckets_between(from_age:, to_age:, span: TIME_BUCKET_SPAN)
    return [] if from_age.nil? || to_age.nil?
    return [] if to_age < from_age

    start = (from_age / span) * span  # 開始年齢をspan刻みに切り捨て
    last  = (to_age / span) * span    # 終了年齢も同様

    # start から last まで span ステップで配列を生成
    (start..last).step(span).map do |s|
      "#{s}-#{s + (span - 1)}"
    end
  end

  # AI提案対象のWantを選定するロジック（urgency + recency スコアリング）
  # 1. notify_enabled: true のWantを優先候補にする
  # 2. urgency（期限が近いほど高スコア）+ recency（最後の提案が古いほど高スコア）で並べ替え
  # 3. notify_enabled のものがなければ全未達成Wantからランダム選択
  def self.select_for_suggestion(user)
    wants = user.wants.where(notify_enabled: true, achieved_at: nil)
                      .includes(:daily_action_suggestions)

    if wants.empty?
      # notify_enabled のWantがない場合はすべての未達成Wantから選ぶ
      wants = user.wants.where(achieved_at: nil).includes(:daily_action_suggestions)
      return nil if wants.empty?
      return wants.sample  # ランダム選択
    end

    # urgency_score（期限の切迫度）と recency_score（前回提案からの経過日数）の合計で降順ソート
    wants.sort_by { |w| [ -(urgency_score(w) + recency_score(w)), w.created_at ] }.first
  end

  private

  # 期限の切迫度スコア（target_date が近いほど高スコア）
  # - 7日以内: 100点
  # - 30日以内: 50点
  # - それ以外: 10点
  # - target_date 未設定: 0点
  def self.urgency_score(want)
    return 0 unless want.target_date

    days = (want.target_date - Date.current).to_i
    return 100 if days <= 7
    return 50  if days <= 30
    10
  end
  private_class_method :urgency_score

  # 前回の提案からの経過日数スコア（日数が多いほど高スコア、上限50点）
  # 一度も提案されていない場合は50点（最優先候補になりやすい）
  def self.recency_score(want)
    last = want.daily_action_suggestions.maximum(:suggested_on)
    return 50 unless last  # 未提案なら最高スコア

    [ (Date.current - last).to_i * 5, 50 ].min  # 1日ごとに5点加算、最大50点
  end
  private_class_method :recency_score

  # フォームから入力された「〇歳までに」を target_date（日付）に変換する
  # バリデーションエラーもここで追加する
  def apply_target_age_input
    age_str = target_age_input.to_s.strip

    if age_str.present?
      # 半角数字以外が含まれていればエラー
      unless age_str.match?(/\A\d+\z/)
        errors.add(:base, "年齢は半角数字で入力してください")
        return
      end
      age = age_str.to_i
      # 1〜120歳の範囲外はエラー
      unless age.between?(1, 120)
        errors.add(:base, "年齢は 1〜120 の範囲で入力してください")
        return
      end
      # 誕生日が未設定では計算できないためエラー
      if user.blank? || user.birthday.blank?
        errors.add(:base, "プロフィールに誕生日を設定してください（年齢から目標日を計算します）")
        return
      end
      # 誕生日 + 入力年数 で target_date を算出（例: 1990/01/01 + 30年 = 2020/01/01）
      self.target_date = user.birthday.to_date + age.years

    elsif target_date.present?
      # 年齢入力なしで直接日付を入力している場合、過去日付はエラー
      if target_date < Date.current
        errors.add(:base, "目標日に過去の日付は設定できません")
      end

    else
      # どちらも入力なし → target_date を nil に（期限なしWant）
      self.target_date = nil
    end
  end

  # notify_enabled: true のWantは1ユーザーにつき1件のみ許可する
  # このWantを true にしたとき、他のWantをすべて false に更新する
  def ensure_single_notify_enabled
    user.wants.where.not(id: id).update_all(notify_enabled: false)
  end

  # target_date と誕生日から time_bucket（年齢帯）を自動計算して保存する
  # 例: target_date が28歳時点 → "20-29"
  def set_time_bucket
    return if target_date.blank?
    return if user.blank? || user.birthday.blank?

    # 目標日時点の年齢を算出（365.25日で割ることでうるう年を考慮）
    age = ((target_date.to_date - user.birthday.to_date).to_i / 365.25).floor
    self.time_bucket = self.class.time_bucket_for_age(age)
  end

  # time_bucket の再計算が必要かどうかを判定する
  # - まだ設定されていない場合
  # - target_date が変わった場合
  # - ユーザーが変わった場合（通常は発生しないが念のため）
  def should_set_time_bucket?
    time_bucket.blank? || will_save_change_to_target_date? || will_save_change_to_user_id?
  end

  # 達成日時の入力値を Time オブジェクトに変換する
  # - 入力が空なら今日の終わり（23:59:59）を返す
  # - Time / Date オブジェクト、または文字列（"2024-01-01"など）を受け付ける
  # - パースに失敗した場合は now（現在時刻）の end_of_day を返す
  def parse_achieved_at(input, now)
    return now.end_of_day if input.blank?

    time =
      case input
      when Time then input
      when Date then input.in_time_zone
      else
        begin
          Time.zone.parse(input.to_s)
        rescue ArgumentError, TypeError
          nil
        end
      end

    (time || now).end_of_day
  end

  # イメージ画像のサイズを3MB以下に制限するバリデーション
  def picture_size
    return unless picture.attached?
    return if picture.blob.byte_size <= 3.megabytes

    errors.add(:picture, "は3MB以下にしてください")
  end

  # 達成画像のサイズを3MB以下に制限するバリデーション
  def achieved_image_size
    return unless achieved_image.attached?
    return if achieved_image.blob.byte_size <= 3.megabytes

    errors.add(:achieved_image, "は3MB以下にしてください")
  end
end
