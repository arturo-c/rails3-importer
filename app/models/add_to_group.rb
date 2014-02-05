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
    rescue => e
      user.err = e
      user.status = 'Error adding user to group.'
    else
      user.err = nil
      user.status = 'User added to group.'
      user.create_submission
    end

    user.save
  end

end
