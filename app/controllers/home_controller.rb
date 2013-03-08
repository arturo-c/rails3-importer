class HomeController < ApplicationController
  def index
    @admins = Admin.all
    if session[:user_info]
      @admin_info = session[:user_info]
    end
  end
end
