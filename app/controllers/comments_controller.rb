class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @want = Want.public_list.find(params[:id])
    @comment = @want.comments.new(comment_params.merge(user: current_user))

    if @comment.save
      redirect_to public_want_path(@want), notice: "コメントを投稿しました"
    else
      redirect_to public_want_path(@want), alert: "コメントを入力してください"
    end
  end

  def destroy
    @comment = current_user.comments.find(params[:id])
    @want = @comment.want
    @comment.destroy
    redirect_to public_want_path(@want), notice: "コメントを削除しました"
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end
end
