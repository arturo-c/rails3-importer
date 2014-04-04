class SessionsController < ApplicationController

  def new
    redirect_to '/auth/allplayers'
  end

  def create
    auth = request.env['omniauth.auth']
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(auth['extra']['access_token'].token, auth['extra']['access_token'].secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    admin = Admin.where(:uuid => auth['uid'].to_s).first || Admin.create_with_omniauth(auth)
    admin.token = auth['extra']['access_token'].token
    admin.secret = auth['extra']['access_token'].secret
    admin.save
    flash[:warning] = 'Syncing groups from AllPlayers.'
    session[:user_id] = admin.id
    session[:user_info] = auth['info']
    session[:user_uuid] = auth['uid']
    admin.get_admin_groups
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
