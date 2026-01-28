class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :birthday ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :birthday ])
  end

  private

  def set_locale
    I18n.locale = :ja
  end
end
