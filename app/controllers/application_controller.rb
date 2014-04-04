class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?
  #before_filter :require_login

  private

  if Rails.env.test?
    prepend_before_filter :stub_current_user

    def stub_current_user
      session[:user_id] = cookies[:stub_user_id] if cookies[:stub_user_id]
    end
  end


  def require_login
    return true if request.fullpath =~ /auth/ #Allow omniauth to work

    if session[:user_id].present?
      current_user
    else
      redirect_to '/' unless request.fullpath == '/'
    end
  end

  def current_user
    begin
      @current_user ||= Admin.find(session[:user_id]) if session[:user_id]
    rescue Exception => e
      nil
    end
  end

  def user_signed_in?
    return true if current_user
  end

  def correct_user?
    @user = Admin.find(params[:id])
    unless current_user == @user
      redirect_to root_url, :alert => 'Access denied.'
    end
  end

  def authenticate_user!
    if !current_user
      redirect_to root_url, :alert => 'You need to sign in for access to this page.'
    end
  end

end
