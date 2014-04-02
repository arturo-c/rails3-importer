class MembersController < ApplicationController
  helper_method :sort_column, :sort_direction, :sortable

  before_filter do
    filter = session[:filter] if session[:filter]
    session[:filter] = filter = {:filter => params[:filter]} if params[:filter]
    session[:filter] = filter = nil if params[:commit] == 'Reset Filters'
    @members = Member.all.where(:admin_uuid => session[:user_uuid])
    # Reset filters.
    @members = process_filter(@members, filter) if filter
  end

  # GET /members
  # GET /members.json
  def index
    session[:filter] = nil unless params[:filter]
    @members = @members.page(params[:page]).per(params[:per_page]) unless params[:format] == 'csv'

    # Retrieve the webform fields
    @webform = {}
    @webform = Webform.where(:uuid => session[:webform_uuid]).first.data if session[:webform_uuid]
    @admin = current_user

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @members }
      format.js { @members }
      format.csv # index.csv.erb
    end
  end

  # GET /members/1
  # GET /members/1.json
  def show
    @member = Member.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @member }
    end
  end

  # GET /members/new
  # GET /members/new.json
  def new
    @member = Member.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @member }
    end
  end

  # GET /members/1/edit
  def edit
    @member = Member.find(params[:id])
  end

  # POST /members
  # POST /members.json
  def create
    r = params[:member]
    @member = Member.where(:email => r[:email], :group_name => r[:group_name], :admin_uuid => session[:user_uuid]).first
    r = @member.attributes.merge(r) unless @member.nil?
    @member = Member.new(r) if @member.nil?
    @member.update_attributes(r) unless @member.nil?

    unless @member.err
      @member.get_member_uuid
    end
    respond_to do |format|
      unless @member.nil?
        format.html { redirect_to @member, notice: 'Member was successfully created.' }
        format.json { render json: @member, status: :created, location: @member }
      else
        format.html { render action: "new" }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /members/1
  # PUT /members/1.json
  def update
    @member = Member.find(params[:id])

    respond_to do |format|
      if @member.update_attributes(params[:member])
        unless @member.err
          @member.get_member_uuid
        end
        format.html { redirect_to @member, notice: 'Member was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /members/1
  # DELETE /members/1.json
  def destroy
    @member = Member.find(params[:id])
    @member.destroy

    respond_to do |format|
      format.html { redirect_to members_url }
      format.json { head :no_content }
    end
  end

  def destroy_all
    @members.each do |member|
      member.destroy
    end
    render :live
  end

  def delete_members
    @members.each do |member|
      member.delete_member
    end
    render :live
  end

  def unblock_members
    @members.each do |member|
      member.unblock_member
    end
    render :live
  end

  def get_duplicates
    @members = Member.find(:all, :group => [:first_name, :last_name, :birthday, :group_uuid], :having => "count(*) > 1" )
    render :live
  end

  def export
    @member = Member.find(params[:id])
    @member.get_member_uuid
    render :live
  end

  def export_all
    @members.each do |member|
      member.get_member_uuid
    end
    render :live
  end

  def import_csv
    admin = Admin.where('uuid' => session[:user_uuid]).first
    SmarterCSV.process(params[:csv].tempfile, {:chunk_size => 100, :strip_chars_from_headers => '"', :col_sep => ','}) do |chunk|
      admin.process_import(chunk)
    end
    redirect_to members_url
  end

  def clear_errors
    @members.update_all(:err => nil)
    render :live
  end

  def live
    @members
  end

  def add_members_job
    @members.each do |member|
      member.add_to_group
    end
    render :live
  end

  def add_to_group_and_subgroups
    @members.each do |member|
      member.add_to_group_and_subgroups
    end
    render :live
  end

  def remove_from_group
    @members.each do |member|
      member.remove_from_group
    end
    render :live
  end

  def remove_from_group_and_subgroups
    @members.each do |member|
      member.remove_from_group_and_subgroups
    end
    render :live
  end


  def get_roles
    @members.each do |member|
      member.get_group_member_roles
    end
    render :live
  end

  def get_submissions
    @members.each do |member|
      member.get_submission(current_user.webform)
    end
    render :live
  end

  def delete_submissions
    @members.each do |member|
      member.delete_submission(current_user.webform)
    end
    render :live
  end

  def get_unique_submissions
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    @members.each do |member|
      #member.get_unique_submission
      testing = {'test1' => 'blah', 'test2' => 'zing'}
      submission = client.create_submission(current_user.webform, member.webform_fields.symbolize_keys, member.uuid)
      testing
    end
    render :live
  end

  def get_webform_data
    @members.each do |member|
      member.get_webform_data(current_user.webform)
    end
    render :live
  end

  def verify_import_roles
    @members.each do |member|
      member.verify_import_roles
    end
    render :live
  end

  def verify_import_submission
    @members.each do |member|
      member.verify_import_submission(current_user.webform)
    end
    render :live
  end

  def assign_all
    @members.each do |member|
      member.assign_submission(current_user.webform)
    end
    render :live
  end

  def assign
    @member = Member.find(params[:id])
    @member.assign_submission(current_user.webform)
    render :live
  end

  def set_completed
    @members.each do |member|
      member.status = params[:set_status][:status]
      member.save
    end
    render :live
  end

  private
  def process_filter(query, params)
    query = query.where(:admin_uuid => session[:user_uuid])
    if params[:filter][:email].present?
      email = params[:filter][:email]
      query = query.where(:email => /.*#{email}.*/)
    end
    if params[:filter][:errors].present?
      errors = params[:filter][:errors]
      query = query.where(:err => /.*#{errors}.*/)
    end
    query = query.where(:status => params[:filter][:status]) if params[:filter][:status].present?
    query = query.where(:first_name => params[:filter][:first_name]) if params[:filter][:first_name].present?
    query = query.where(:member_id => params[:filter][:member_id]) if params[:filter][:member_id].present?
    query = query.where(:last_name => params[:filter][:last_name]) if params[:filter][:last_name].present?
    if params[:filter][:roles].present?
      roles = params[:filter][:roles]
      query = query.where(:roles => /.*#{roles}.*/)
    end

    # Filter by the group selected and all subgroups if checkbox enabled.
    if (params[:filter][:subgroups].present? && params[:filter][:subgroups] == "1" && params[:filter][:group_name].present?)
      group = Group.where(:name => params[:filter][:group_name]).first
      # Reset the subgroups variable.
      @subgroups = []
      # Recursive function to get all subgroups.
      get_subgroups(group.uuid)
      # Include the top level group.
      @subgroups << group.name
      query = query.in(group_name: @subgroups)
    elsif params[:filter][:group_name].present?
      group = params[:filter][:group_name]
      query = query.where(:group_name => /.*#{group}.*/)
    end
    return query
  end

  # Recursive function to get all the groups subgroups.
  def get_subgroups(group_uuid)
    @subgroups ||= []

    subgroups = Group.any_of(:groups_above => group_uuid).entries
    return if subgroups.first.nil?
    subgroups.each do |subgroup|
      @subgroups << subgroup.name
      get_subgroups(subgroup.uuid)
    end
  end

  private
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    view_context.link_to(title, params.merge(:sort => column, :direction => direction, :page => nil), {:class => css_class})
  end

  def sort_column
    Member.fields.keys.include?(params[:sort]) ? params[:sort] : "email"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
  end

  def process_import(r, admin)
    r[:admin_uuid] = admin.uuid
    r[:status] = 'Processing'
    errors = ''
    if r[:gender]
      r[:gender] = r[:gender].downcase
      r[:gender] = 'm' if r[:gender].casecmp('male') == 0
      r[:gender] = 'f' if r[:gender].casecmp('female') == 0
      unless r[:gender] == 'm' || r[:gender] == 'f'
        errors += 'Invalid Gender(enter m or f).'
      end
    end
    if r[:birthday]
      begin
        if r[:birthday].include? "/"
          d = r[:birthday].split("/")
          if d[2].length == 2
            year = d[2]
            y = '20' + year if year < '15'
            y = "19" + year if year > '14'
            d[2] = y
            r[:birthday] = Date.strptime(d.join('/'), "%m/%d/%Y")
          else
            r[:birthday] = Date.strptime(r[:birthday], "%m/%d/%Y")
          end
        else
          r[:birthday] = Date.parse(r[:birthday])
        end
      rescue
        errors += 'Invalid Date(use format 1985-08-22).'
      else
        today = Date.today
        child = today.prev_year(13)
        if r[:birthday] > child
          errors += 'Parent email is required for child under 13.' unless r[:parent_email]
        end
        r[:birthday] = r[:birthday].to_s
      end
    end
    if r[:join_date]
      begin
        if r[:join_date].include? "/"
          r[:join_date] = Date.strptime(r[:join_date], "%m/%d/%Y")
        else
          r[:join_date] = Date.parse(r[:join_date])
        end
      rescue
        errors += 'Invalid date for join date'
      end
      r[:join_date] = r[:join_date].to_s
    end
    if r[:roles]
      roles = r[:roles].split(",").collect(&:strip)
      flags = r[:flags].split(",").collect(&:strip) if r[:flags]
      r[:roles] = Hash.new
      roles.each do |role|
        r[:roles][role] = flags.shift
      end
    end
    if r[:email]
      r[:email_] = r[:email].strip.downcase
    end
    if r[:parent_email]
      r[:parent_email_] = r[:parent_email].strip.downcase
    end
    if r[:first_name]
      r[:first_name_] = r[:first_name].strip.downcase
    else
      errors += 'Missing first name.'
    end
    if r[:last_name]
      r[:last_name_] = r[:last_name].strip.downcase
    else
      errors += 'Missing last name.'
    end
    r[:uuid] = r[:uuid].strip if r[:uuid]
    r[:err] = errors
    r[:status] = 'Invalid Data' unless errors == ''

    r[:webform_fields] = Hash.new
    r.each do |key, value|
      if key.inspect.include? 'webform_'
        v = key.inspect.split ':webform_'
        admin.webform_fields.each do |k, s|
          if s.parameterize.underscore == v[1]
            r[:webform_fields][k] = value
          end
        end
      end
    end
    return r
  end

end
