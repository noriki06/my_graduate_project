class PagesController < ApplicationController
  def top
    redirect_to wants_path if user_signed_in? && request.path == "/"
  end

  def die_with_zero
  end

  def terms
  end

  def privacy
  end
end
