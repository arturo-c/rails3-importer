class MembersController < ApplicationController

  # GET /members
  # GET /members.json
  def index
    query = Member.all.where(:admin_uuid => session[:user_uuid])

    # Reset filters.
    if params[:commit] == 'Reset Filters'
      params.delete('filter')
    elsif params.has_key?(:filter)
      query = process_filter(query, params)
      @@csv_members = query
    end

    # Introducing class variable for filters so that filters remain consistent
    # throughout ajax calls.
    @@full_members = query
    @@csv_members ||= @@full_members

    @@members = @members = query.page(params[:page]).per(params[:per_page])

    # Take the pagination out of the csv export.
    @members = @@csv_members if params[:format] == 'csv'

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
    @members = @@full_members
    @members.each do |member|
      member.destroy
    end
  end

  def export
    @member = Member.find(params[:id])
    @member.get_member_uuid
    render :live
  end

  def export_all
    @members = @@full_members
    @members.each do |member|
      member.get_member_uuid
    end
    render :live
  end

  def import_csv
    count = Member.count
    new_users = 0
    SmarterCSV.process(params[:csv].tempfile, {:chunk_size => 100, :strip_chars_from_headers => '"', :col_sep => ','}) do |chunk|
      #Member.first.process_csv(chunk) # pass chunks of CSV-data to Resque workers for parallel processing
      #Resque.enqueue(ProcessCsv, chunk)
      chunk.each do |c|
        c = process_row(c)
        group = Group.where(:uuid => c[:group_uuid]).first if c[:group_uuid]
        group = Group.where(:name => c[:group_name]).first unless c[:group_uuid]
        c[:group_name] = group.name if group
        c[:status] = 'Group not found' unless group
      end
      Member.collection.insert(chunk)
    end
    redirect_to members_url
  end

  def import_csv_2
    SmarterCSV.process(params[:csv].tempfile, {:strip_chars_from_headers => '"', :col_sep => ','}) do |chunk|
      chunk.each do |row|
        r = row.to_hash.with_indifferent_access.symbolize_keys
        r = process_row(r)
        group = Group.where(:uuid => r[:group_uuid]).first if (r[:group_uuid] && !r[:group_name])
        group = Group.where(:name => r[:group_name]).first unless group
        r[:group_name] = group.name if group
        member = Member.find(r[:_id])
        unless member.nil?
          member.update_attributes(member.attributes.merge(r))
          member.status = 'Group not found' unless group
          member.save
        end
      end
    end
    redirect_to members_url
  end

  def clear_errors
    @members = @@members
    @members.update_all(:err => nil)
    render :live
  end

  def live
    @@members ||= @members
    @members = @@members
  end

  def add_members_job
    @@full_members.each do |member|
      member.add_to_group
    end
    @members = @@full_members
    render :live
  end

  def add_to_group_and_subgroups
    @@full_members.each do |member|
      member.add_to_group_and_subgroups
    end
    @members = @@full_members
    render :live
  end

  def remove_from_group
    @@full_members.each do |member|
      member.remove_from_group
    end
    @members = @@full_members
    render :live
  end

  def remove_from_group_and_subgroups
    @@full_members.each do |member|
      member.remove_from_group_and_subgroups
    end
    @members = @@full_members
    render :live
  end


  def get_roles
    @@full_members.each do |member|
      member.get_group_member_roles
    end
    @members = @@full_members
    render :live
  end

  def get_submissions
    @@full_members.each do |member|
      member.get_submission
    end
    @members = @@full_members
    render :live
  end

  def get_webform_data
    @@full_members.each do |member|
      member.get_webform_data
    end
    @members = @@full_members
    render :live
  end

  def assign_all
    @@full_members.each do |member|
      member.assign_submission
    end
    @members = @@full_members
    render :live
  end

  def assign
    @member = Member.find(params[:id])
    @member.assign_submission
    render :live
  end

  def set_completed
    @@full_members.each do |member|
      member.status = params[:set_status][:status]
      member.save
    end
    @members = @@full_members
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

  def process_row(r)
    r[:admin_uuid] = session[:user_uuid]
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
      end
      today = Date.today
      child = today.prev_year(13)
      if r[:birthday] > child
        errors += 'Parent email is required for child under 13.' unless r[:parent_email]
      end
      r[:birthday] = r[:birthday].to_s
    end
    r[:roles] = r[:roles].split(",").collect(&:strip) if r[:roles]
    r[:email] = r[:email].gsub(/\s+/, "").strip if r[:email]
    r[:parent_email] = r[:parent_email].gsub(/\s+/, "").strip if r[:parent_email]
    r[:first_name] = r[:first_name].strip if r[:first_name]
    r[:last_name] = r[:last_name].strip if r[:last_name]
    r[:first_name].capitalize!
    r[:last_name].capitalize!
    r[:uuid] = r[:uuid].strip if r[:uuid] if r[:uuid]
    r[:err] = errors
    r[:status] = 'Invalid Data' unless errors == ''
    r[:status] = 'Processing' if errors == ''

    return r
  end

end
