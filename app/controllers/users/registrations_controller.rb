class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(_resource)
    edit_birthday_path
  end

  def after_inactive_sign_up_path_for(_resource)
    edit_birthday_path
  end
end
