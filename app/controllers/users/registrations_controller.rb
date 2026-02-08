class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # サインアップ後は生年月日入力へ
  def after_sign_up_path_for(_resource)
    edit_birthday_path
  end

  def after_inactive_sign_up_path_for(_resource)
    edit_birthday_path
  end

  # ★ プロフィール更新後は wants のindexへ
  def after_update_path_for(_resource)
    wants_path
  end

  # サインアップ/プロフィール編集で許可する項目
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name birthday])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name birthday])
  end

  # 名前・生年月日だけならパスワード不要で更新できるようにする
  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      resource.update_without_password(params.except(:current_password))
    else
      super
    end
  end
end
