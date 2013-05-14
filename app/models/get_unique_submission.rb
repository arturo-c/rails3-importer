class GetUniqueSubmission
  @queue = :get_unique_submission

  def self.perform(user_id)
    user = Member.find(user_id)
    admin = Admin.where(:uuid => user.admin_uuid).first
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    err = nil
    begin
      group = Group.where(:uuid => user.group_uuid).first if user.group_uuid
      group = Group.where(:name => user.group_name).first unless user.group_uuid
      raise 'Group Not Found' unless group
      raise 'No org webform to get submission' unless group.org_webform_uuid
      fname = HTMLEntities.new.decode(user.first_name)
      lname = HTMLEntities.new.decode(user.last_name)
      email = HTMLEntities.new.decode(user.parent_email)
      submission = client.get_submission(group.org_webform_uuid, nil, nil, {'first_name' => fname, 'last_name' => lname, 'email_address' => email}) unless user.birthday
      submission = client.get_submission(group.org_webform_uuid, nil, nil, {'first_name' => fname, 'last_name' => lname, 'birthday' => user.birthday}) if user.birthday
    rescue => e
      begin
        raise 'No submission found' unless submission
      rescue => e
        user.status = 'Error getting user webform submission'
        err = e
      end
    end
    if err.nil?
      user.update_attributes(:submission_id => submission['sid'])
      if submission['uuid'] == user.uuid
        user.status = 'Webform assigned'
      else
        user.status = 'Unassigned submission'
      end
      user.err = ''
    else
      user.err = err
    end
    user.save
  end

end
