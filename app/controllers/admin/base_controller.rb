class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  layout "admin"

  private

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者のみアクセスできます。"
    end
  end
end
