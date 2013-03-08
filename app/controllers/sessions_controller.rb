class SessionsController < ApplicationController

  def new
    redirect_to '/auth/allplayers'
  end

  def create
    auth = request.env["omniauth.auth"]
    AllPlayers.new(ENV["HOST"], 'oauth', auth['extra'][:access_token])
    admin = Admin.where(:uuid => auth['uid'].to_s).first || Admin.create_with_omniauth(auth)
    admin.token = auth['extra']['access_token'].token
    admin.secret = auth['extra']['access_token'].secret
    admin.save
    session[:user_id] = admin.id
    session[:user_info] = auth['info']
    session[:user_uuid] = auth['uid']
    redirect_to root_url, :notice => 'Signed in!'

  end

  def destroy
    reset_session
    @@full_members = nil
    @@full_groups = nil
    @@members = nil
    @@groups = nil
    redirect_to root_url, :notice => 'Signed out!'
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end

end
