class GroupsController < ApplicationController
  # GET /groups
  # GET /groups.json
  def index
    admin = Admin.find(session[:user_id])
    query = admin.groups.all

    # Reset filters.
    if params[:commit] == 'Reset Filters'
      params.delete('filter')
    elsif params.has_key?(:filter)
      query = process_filter(query)
      @@csv_groups = query
    end

    # Introducing class variable for filters so that filters remain consistent
    # throughout ajax calls.
    @@full_groups = query
    @@csv_groups ||= @@full_groups
    @distinct_status = admin.groups.all.distinct(:status)

    @@groups = @groups = query.page(params[:page]).per(params[:per_page])

    # Take the pagination out of the csv export.
    @groups = @@csv_groups if params[:format] == 'csv'

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @groups }
      format.js { @groups }
      format.csv # index.csv.erb
    end
  end

  def get_groups_data
    @groups = @@full_groups
    @groups.each do |group|
      group.get_group if group.uuid
    end
    
  end

  def get_groups_uuid
    @groups = @@full_groups
    @groups.each do |group|
      group.get_group_uuid(session[:user_id ])
    end
  end

  def import_csv
    admin = Admin.find(session[:user_id])
    group = admin.groups.find_or_create_by(:uuid => params[:group][:group_template])
    admin.group_template = group.id
    admin.save
    admin.create_group_template(group.id)
    SmarterCSV.process(params[:csv].tempfile, {:chunk_size => 100, :strip_chars_from_headers => '"', :col_sep => ','}) do |chunk|
      admin.process_group_import(chunk)
    end
    redirect_to groups_url
  end

  def verify_group_import
    admin = Admin.find(session[:user_id])
    group = admin.groups.find_or_create_by(:uuid => params[:group][:group_template])
    #admin.create_group_template(group.id)
    SmarterCSV.process(params[:csv].tempfile, {:chunk_size => 200, :strip_chars_from_headers => '"', :col_sep => ','}) do |chunk|
      admin.verify_group_import(chunk)
    end
    redirect_to groups_url
  end

  def create_groups_below
    admin = Admin.find(session[:user_id])
    @groups = @@csv_groups
    @groups.each do |group|
      group.create_groups_below(session[:user_id], admin.group_template, group.id)
    end
    @groups
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new(params[:group])
    @group[:local] = true
    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, notice: 'New group was successfully created.' }
        format.json { render json: @group, status: :created, location: @group }
      else
        format.html { render action: "new" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:new_group])
        format.html { redirect_to @group, notice: 'New group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find(params[:id])
    @group.update_attributes(:deleted => true)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.group_delete(@group[:uuid])

    respond_to do |format|
      format.html { redirect_to groups_url }
      format.json { head :no_content }
    end
  end

  def destroy_all
    @groups = @@full_groups
    @groups.each do |group|
      group.destroy
    end
    @groups == @@full_groups = nil
  end

  def destroy_all_allplayers
    @groups = @@csv_groups
    @groups.each do |group|
      group.delete_group
    end
    @groups = @@full_groups = nil
  end    

  def export
    group = Group.find(params[:id])
    group.create_group(session[:user_id])
    redirect_to groups_url
  end

  def live
    @@groups ||= @groups
    @groups = @@groups
  end

  def export_all
    @groups = @@csv_groups
    @groups.each do |group|
      if group.payee
        template = Group.where(:uuid => group.template).first
        toplevel = Group.where(:uuid => group.payee).first
        group.create_one_group(session[:user_id], template.id, toplevel.id)
      else
        group.create_group(session[:user_id])
      end
    end
    @groups
  end

  def clear_errors
    @groups = @@groups
    @groups.update_all(:err => nil)
    @groups
  end

  def search_duplicates
    @groups == @@groups
    @groups.each do |group|
      group.search_duplicates
    end
  end

  def get_members
    @group = Group.find(params[:id])
    @group.get_subgroups_members
    @group
  end

  def get_all_members
    @groups = @@full_groups
    @groups.each do |group|
      group.get_group_members
    end
    @groups
  end

  def get_roles
    @group = Group.find(params[:id])
    @group.get_subgroups_members_roles
    @group
  end

  def get_groups
    admin = Admin.find(session[:user_id])
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    groups = client.user_groups_list('6219590a-b059-11e3-8c9b-22000a9b80fe', {:limit => 0})
    groups.each do |g|
      ap_group = {
        :uuid => g['uuid'],
        :title => g['title'],
        :title_lower => g['title'].strip.downcase,
        :description => g['description'],
        :user_uuid => '6219590a-b059-11e3-8c9b-22000a9b80fe',
        :status => 'AllPlayers'
      }
      admin.groups.create(ap_group)
    end
    #admin.get_admin_groups
  end

  def get_org_groups
    admin = Admin.where('uuid' => session[:user_uuid]).first
    admin.get_org_groups
  end

  def update_groups
    @groups = @@full_groups
    @groups.each do |group|
      group.update_group
    end
    @groups
  end

  def clone_groups
    @groups = @@full_groups
    @groups.each do |group|
      group.clone_group(group.template)
    end
    @groups
  end

  def set_store_payee
    @groups = @@full_groups
    @groups.each do |group|
      group.set_store_payee(group.uuid) unless group.payee
      group.set_store_payee(group.payee) if group.payee
    end
    @groups
  end

  def clone_webforms
    @groups = @@full_groups
    @groups.each do |group|
      group.clone_forms(group.payee, false, nil) if group.payee
      group.clone_forms(group.template, true, group.user_uuid) unless group.payee
    end
    @groups
  end

  private
  def create_import(group, client)
    more_params = {
      :group_type => group.group_type,
      :web_address => group.title.parameterize.underscore,
      :groups_above => [group.group_above]
    }
    count = 0
    begin
      address = {
        :zip => group.address_zip,
        :street => group.address_street,
        :city => group.address_city,
        :state => group.address_state
      }
      ap_group = client.group_create(
        group.title,
        group.description,
        address,
        {0 => group.category},
        more_params
      )
    rescue AllPlayers::Error => e
      if e.respond_to?(:code)
        if e.code == '406' && e.error.include?('already taken')
          count = count + 1
          more_params[:web_address] = group.title.parameterize.underscore + '_' + count.to_s
          retry
        end
      end
    else
      group.status = 'Imported'
      group.uuid = ap_group['uuid'] if ap_group
    ensure
      group.save
    end
    group
  end

  def process_filter(query)
    filter = params[:filter]
    query = query.where(:status => filter[:status]) if filter[:status].present?
    query = query.where(:uuid => filter[:uuid]) if filter[:uuid].present?
    # Filter by the group selected and all subgroups if checkbox enabled.
    if (filter[:subgroups].present? && filter[:subgroups] == "1" && filter[:name].present?)
      group = query.where(:name => params[:filter][:name]).first
      # Reset the subgroups variable.
      @subgroups = []
      # Recursive function to get all subgroups.
      get_subgroups(group.uuid)
      # Include the top level group.
      @subgroups << group.name
      query = query.in(name: @subgroups)
    elsif filter[:name].present?
      group = filter[:name]
      query = query.where(:title => /.*#{group}.*/)
    end
    return query
  end
end
