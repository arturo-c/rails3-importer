class GetSubmission
  @queue = :get_submission

  def self.perform(user_id)
    user = Member.find(user_id)
    admin = Admin.where(:uuid => user.admin_uuid).first
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    err = nil
    submission = nil
    begin
      group = Group.where(:uuid => user.group_uuid).first if user.group_uuid
      group = Group.where(:name => user.group_name).first unless user.group_uuid
      raise 'Group Not Found' unless group
      raise 'No org webform to get submission' unless group.org_webform_uuid
      fname = HTMLEntities.new.decode(user.first_name)
      lname = HTMLEntities.new.decode(user.last_name)
      submission = client.get_submission(group.org_webform_uuid, nil, user.uuid)
    rescue => e
      begin
        user.status = 'Submission assigned to user not found, searching for unassigned.'
        submission = client.get_submission(group.org_webform_uuid, nil, nil, {'profile__field_firstname__profile' => fname, 'profile__field_lastname__profile' => lname, 'profile__field_birth_date__profile' => user.birthday}) if (user.birthday)
      rescue => e
        user.status = 'Submission not found.'
        err = e
      else
        user.status = 'Unassigned submission found.'
      end
    else
      user.status = 'Assigned submission found.'
    end

    if err.nil?
      user.submission_id = submission['sid']
      user.submission_uuid = submission['uuid']
      user.old_group = submission['data']['organization_name'].first if submission['data']['organization_name']
      user.old_member_id = submission['data']['org__sequential_id__org_webform'].first if submission['data']['org__sequential_id__org_webform']
      user.old_user_uuid = submission['user_uuid']
    else
      user.err = err
    end
    user.save
  end

end
