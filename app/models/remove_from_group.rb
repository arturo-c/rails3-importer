class RemoveFromGroup
  @queue = :remove_from_group

  def self.perform(user_id, group_uuid = nil)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    begin
      raise 'No group specified.' unless user.group_name
      group = Group.where(:name => /.*#{user.group_name}.*/).first
      raise 'Group not found.' unless group

      group_uuid ||= group.uuid
      leave = client.user_leave_group(group_uuid, user.uuid)
    rescue => e
      if e.to_s.include?('removed from')
        user.status = 'User removed from group'
        user.err = ''
      else
        user.err = e.to_s
        user.status = 'Error removing user from group'
      end
    else
      user.status = 'User removed from group'
      user.err = ''
    end

    user.save
  end

end
