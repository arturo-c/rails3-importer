class AdminsController < ApplicationController

  def index
    @admin ||= current_user
  end

  def edit
    @admin = Admin.find(params[:id])
  end
  
  def update
    @admin = Admin.find(params[:id])
    if !params[:admin].nil?
      org = params[:admin][:organization]
      @group = @admin.groups.find_by_name(@admin.organization)
      @group = @admin.groups.find_by_name(org) unless org.nil?
      @admin.update_attributes(:organization => org) unless org.nil?
      if params[:admin][:webform] && @admin.organization
        @admin.get_org_groups(@group.uuid)
        webform = @group.webforms.find(params[:admin][:webform])
        client = AllPlayers::Client.new(ENV["HOST"])
        client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
        form = client.get_webform(webform.uuid)
        fields = Hash.new
        form['webform']['components'].each do |cid, value|
          fields[value['form_key']] = value['name']
        end
        @admin.webform_fields = fields
        @admin.webform = webform.uuid
        @admin.save
        redirect_to members_url
        return
      elsif @group.nil?
        flash[:warning] = 'Organization not found.'
        render :index
        return
      end
    else params[:admin].nil?
      flash[:warning] = 'Fields required.'
      render :index
      return
    end

    if @group.webforms.empty?
      client = AllPlayers::Client.new(ENV["HOST"])
      client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
      @webforms = client.group_webforms_list(@group.uuid)
      @webforms.each do |uuid, name|
        @group.webforms.build(:uuid => uuid, :name => name)
      end
      @group.save
    end
    render :index
  end

  def show
    @admin = Admin.find(params[:id])
  end

end
