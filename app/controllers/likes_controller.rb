# LikesController
# 公開 Want に対するいいね（Like）の作成と削除を担当する。
# ログインが必須で、非公開WantへのいいねはWantが見つからず 404 になる。
class LikesController < ApplicationController
  # ログインしていないユーザーはいいねできない
  before_action :authenticate_user!
  # いいね対象のWantを事前に取得する（public_list スコープで非公開Wantを除外）
  before_action :set_want

  # ===== いいね作成 =====
  # find_or_create_by を使うことで同じユーザーが同じWantに2回いいねするのを防ぐ
  # （Likeモデルにもユニーク制約があるが、アプリ側でも重複を避ける）
  def create
    @want.likes.find_or_create_by(user: current_user)
    # 元のページ（詳細ページか一覧ページ）に戻る
    redirect_back fallback_location: public_want_path(@want)
  end

  # ===== いいね削除 =====
  # current_user のいいねのみを対象にすることで他ユーザーのいいねを削除できないようにする
  def destroy
    like = @want.likes.find_by(user: current_user)
    like&.destroy  # いいねが存在しない場合は何もしない（&. でnilチェック）
    redirect_back fallback_location: public_want_path(@want)
  end

  private

  # public_list スコープを使うことで published: true のWantのみ操作対象にする
  # 非公開WantのIDを直接叩かれても 404 になる
  def set_want
    @want = Want.public_list.find(params[:id])
  end
end
