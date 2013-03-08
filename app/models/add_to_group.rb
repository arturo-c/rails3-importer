class AddToGroup
  @queue = :add_to_group

  def self.perform(user_id)
    user = Member.find(user_id)
    admin = Admin.where(:uuid => user.admin_uuid).first
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    begin
      raise 'No group specified.' unless user.group_name
      group = Group.where(:name => user.group_name).first
      raise 'Group not found.' unless group
      raise 'No role specified.' unless (user.roles && !user.roles.empty?)
      join = client.user_join_group(group.uuid, user.uuid, user.roles.first, {:should_pay => 0}, group.org_webform_uuid)
    rescue => e
      user.err = e.to_s
      user.status = 'Error adding user to group.'
    else
      user.status = 'User added to group.' if join['type'] == 'subscribed'
      user.err = ''
    end

    user.save
  end

end
