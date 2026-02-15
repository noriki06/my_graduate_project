class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(_resource)
    edit_birthday_path
  end

  def after_inactive_sign_up_path_for(_resource)
    edit_birthday_path
  end

  def after_update_path_for(_resource)
    wants_path
  end

  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      resource.update_without_password(params.except(:current_password))
    else
      super
    end
  end
end
