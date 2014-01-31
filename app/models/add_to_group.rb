class AddToGroup
  @queue = :add_to_group

  def self.perform(user_id, group_uuid = nil)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    user.err = nil
    user.status = nil
    err = nil
    begin
      raise 'No group specified.' unless user.group_name
      group = Group.where(:uuid => user.group_uuid).first if user.group_uuid
      group = Group.where(:name => user.group_name).first unless user.group_uuid
      raise 'Group not found.' unless group
      raise 'No role specified.' unless (user.roles && !user.roles.empty?)
      group_uuid ||= group.uuid
      time = Time.now
      time = time.year.to_s + "-" + time.month.to_s + "-" + time.day.to_s
      join_date = user.join_date ||= time
      user.roles.each do |role, flag|
        if flag.nil?
          client.user_join_group(group_uuid, user.uuid, role.strip, {:should_pay => 0, :join_date => join_date})
        else
          client.user_join_group(group_uuid, user.uuid, role.strip, {:should_pay => 0, :join_date => join_date, :flag => flag})
          if flag != 'Active'
            client.user_join_group(group_uuid, user.uuid, role.strip, {:should_pay => 0, :join_date => join_date, :unflag => 'Active'})
          end
        end
      end
      group = Group.where(:uuid => user.group_uuid).first
      raise 'No org webform to get submission' unless group.org_webform_uuid
      fname = HTMLEntities.new.decode(user.first_name)
      lname = HTMLEntities.new.decode(user.last_name)
      begin
        submission = nil
        submission = client.get_submission(group.org_webform_uuid, nil, user.uuid)
      rescue => e
        begin
          raise 'Skipping checking for org submissions for now'
          submission = client.get_submission(group.org_webform_uuid, nil, nil, {'profile__field_firstname__profile' => fname, 'profile__field_lastname__profile' => lname, 'profile__field_birth_date__profile' => user.birthday}) if (user.birthday)
          client.assign_submission(group.org_webform_uuid, submission['uuid'], user.uuid) unless submission['user_uuid'] == user.uuid
        rescue => e
          begin
            puts 'Creating submission'
            if user.member_id.nil? || (user.member_id && user.member_id == 0)
              member_id = 'Auto Generated'
            else
              member_id = user.member_id
            end
            puts member_id
            if user.email
              email = user.email
            else
              email = user.parent_email
            end
            puts email
            user.country ||= nil
            user.phone ||= nil
            user.address_2 ||= nil
            submission = client.create_submission(group.org_webform_uuid, {'profile__field_firstname__profile' => fname, 'profile__field_lastname__profile' => lname, 'profile__field_birth_date__profile' => user.birthday, 'profile__field_email__profile' => email, 'org__sequential_id__org_webform' => member_id, 'profile__field_address_street__profile' => user.address_1, 'profile__field_address_additional__profile' => user.address_2, 'profile__field_address_city__profile' => user.city, 'profile__field_address_province__profile' => user.state, 'profile__field_address_postal_code__profile' => user.zip, 'profile__field_address_country__profile' => user.country, 'profile__field_phone__profile' => user.phone, 'organization_name' => user.group_name}, user.uuid)
            user.submission_id = submission['sid']
            puts submission['id']
          rescue => e
            err = e
            user.status = 'Error creating submission'
          end
        end
      end
    rescue => e
      err = e
      user.status = 'Error adding user to group.'
    end

    if err.nil?
      user.status = 'User added to group and assigned submission'
      puts submission.to_yaml
      user.submission_id = submission['sid']
      user.submission_uuid = submission['uuid']
      user.verify_import
    else
      user.err = err
    end

    user.save
  end

end
