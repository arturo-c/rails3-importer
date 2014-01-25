class AddToGroup
  @queue = :add_to_group

  def self.perform(user_id, group_uuid = nil)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
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
      flags = nil
      flags = user.flags if user.flags
      user.roles.each do |role|
        if flags.nil?
          client.user_join_group(group_uuid, user.uuid, role.strip, {:should_pay => 0, :join_date => join_date})
        else
          flag = flags.shift
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
        submission = client.get_submission(group.org_webform_uuid, nil, nil, {'first_name' => fname, 'last_name' => lname, 'birthday' => user.birthday}) if (!user.uuid && user.birthday)
        client.assign_submission(group.org_webform_uuid, submission['sid'], user.uuid) unless submission['uuid']
      rescue => e
        begin
          user.member_id ||= nil
          email = user.email ? user.email : user.parent_email
          user.country ||= nil
          user.phone ||= nil
          user.address_2 ||= nil
          submission = client.create_submission(group.org_webform_uuid, {1 => fname, 2 => lname, 4 => user.birthday, 5 => email, 6 => user.member_id, 8 => user.address_1, 9 => user.address_2, 10 => user.city, 11 => user.state, 12 => user.zip, 13 => user.country, 15 => user.phone, 16 => user.group_name}, user.uuid)
          user.submission_id = submission['sid']
        rescue => e
          user.err = e.to_s
          user.status = 'Error creating submission'
        else
          user.err = nil
          user.status = 'User import completed'
          user.verify_import
        end
      end
    rescue => e
      user.err = e.to_s
      user.status = 'Error adding user to group.'
    end

    user.save
  end

end
