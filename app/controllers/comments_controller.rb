# CommentsController
# 公開 Want の詳細ページへのコメント投稿・削除を担当する。
# 自分が投稿したコメントのみ削除できる。
class CommentsController < ApplicationController
  # ログインしていないユーザーはコメントできない
  before_action :authenticate_user!

  # ===== コメント投稿 =====
  def create
    # public_list スコープで published: true のWantのみ対象にする（非公開Wantへの投稿を防ぐ）
    @want = Want.public_list.find(params[:id])
    # コメントのユーザーをログインユーザーに固定（フォームから user_id を偽装できないよう merge で上書き）
    @comment = @want.comments.new(comment_params.merge(user: current_user))

    if @comment.save
      redirect_to public_want_path(@want), notice: "コメントを投稿しました"
    else
      # バリデーション失敗（content が空など）の場合は詳細ページに戻してアラートを表示
      redirect_to public_want_path(@want), alert: "コメントを入力してください"
    end
  end

  # ===== コメント削除 =====
  def destroy
    # current_user.comments で検索することで自分のコメントのみ削除可能にする
    # 他ユーザーのコメントIDを直接叩かれても 404 になる
    @comment = current_user.comments.find(params[:id])
    @want = @comment.want  # 削除後にリダイレクトするWantを取得
    @comment.destroy
    redirect_to public_want_path(@want), notice: "コメントを削除しました"
  end

  private

  # コメントフォームで受け付けるパラメータのホワイトリスト（content のみ）
  def comment_params
    params.require(:comment).permit(:content)
  end
end
